"""Build a stub monorepo for trigger (description) evals.

The trigger queries name real-looking files ("controllers/quota.go", "worker/lease.go").
In an empty project root the eval model looks for them, finds nothing, and asks the user
for the code instead of loading a skill, so every positive query scores as a miss. This
script writes a short, plausible file for every path the queries mention, positives and
near-miss negatives alike, so the model's decision rests on the description.

Run: python3 plugins/proof-skills/evals/triggers/make_trigger_root.py <dir>    (creates <dir>/.claude too,
     unless --no-claude-dir; the `claude plugin eval` trigger cases use that form)
"""
import pathlib
import sys

FILES = {
    # ---- formal-verify ----
    "services/notify/sender.py": '''import asyncio

async def send_notification(redis, mailer, msg):
    key = f"sent:{msg.id}"
    if await redis.exists(key):
        return "duplicate"
    await mailer.send(msg.to, msg.subject, msg.body)
    await redis.set(key, 1, ex=86400)
    return "sent"
''',
    "controllers/quota.go": '''package controllers

func (c *QuotaController) reconcile(ctx context.Context, ns string) error {
	usage, err := c.etcd.Get(ctx, "/quota/usage/"+ns)
	if err != nil {
		return err
	}
	pods, _ := c.pods.List(ns)
	next := usage.Value + delta(pods)
	_, err = c.etcd.Put(ctx, "/quota/usage/"+ns, next)
	return err
}
''',
    "src/main/kotlin/InventoryService.kt": '''class InventoryService(private val repo: StockRepo) {
    fun reserve(sku: String): Boolean {
        val stock = repo.stock(sku)
        if (stock > 0) {
            repo.decrement(sku)
            return true
        }
        return false
    }
}
''',
    "crates/runner/src/sched.rs": '''pub fn run(dag: &Dag, pool: &Pool) {
    let (tx, rx) = channel();
    let mut ready: Vec<TaskId> = dag.roots();
    let mut running = 0;
    while !ready.is_empty() || running > 0 {
        while let Some(t) = ready.pop() { running += 1; pool.spawn(t, tx.clone()); }
        match rx.recv().unwrap() {
            Done(t) => { running -= 1; ready.extend(dag.unblocked_by(t)); }
            Failed(t) if dag.retries_left(t) > 0 => { pool.spawn(t, tx.clone()); }
            Failed(_) => { running -= 1; }
        }
    }
}
''',
    "docs/rfc/017-leader.md": '''# RFC 017: Leader election with Postgres leases

Each node runs every 2s: `UPDATE leader SET holder=$me, expires=now()+'10s'
WHERE id=1 AND (holder=$me OR expires < now())`. If one row is updated, the node is leader
until `expires`. Leaders stop work when their local clock passes `expires`.
''',
    "formal/cache-coherence/CacheCoherence.tla": '''---- MODULE CacheCoherence ----
EXTENDS Naturals
VARIABLES db, cache
Init == db = 0 /\\ cache = [present |-> FALSE, val |-> 0]
Write == db' = db + 1 /\\ cache' = [cache EXCEPT !.present = FALSE]
Fill == cache' = [present |-> TRUE, val |-> db] /\\ UNCHANGED db
Next == Write \\/ Fill
Coherent == cache.present => cache.val = db
====
''',
    "cache/store.py": '''class Store:
    def get(self, k):
        v = self.cache.get(k)
        if v is None:
            v = self.db.read(k)
            self.cache.set(k, v, ttl=300)
        return v

    def put(self, k, v):
        self.db.write(k, v)
        self.cache.delete(k)
''',
    "specs/Queue.tla": '''---- MODULE Queue ----
EXTENDS Naturals, Sequences
CONSTANTS Workers, N
VARIABLES q, done
Init == q = <<>> /\\ done = {}
Enq(i) == q' = Append(q, i) /\\ UNCHANGED done
Deq(w) == q # <<>> /\\ done' = done \\cup {Head(q)} /\\ q' = Tail(q)
Next == (\\E i \\in 1..N : Enq(i)) \\/ (\\E w \\in Workers : Deq(w))
====
''',
    "specs/MC.cfg": "CONSTANTS Workers = {w1, w2}\n  N = 3\nINIT Init\nNEXT Next\n",
    "lib/ratelimit.ts": '''export class TokenBucket {
  private tokens: number;
  constructor(private shared: Int32Array, private cap: number) { this.tokens = cap; }
  take(): boolean {
    const t = Atomics.load(this.shared, 0);
    if (t <= 0) return false;
    Atomics.store(this.shared, 0, t - 1);
    return true;
  }
}
''',
    "pipeline/sink.py": '''class S3Sink:
    def __init__(self, consumer, s3, batch_size=500):
        self.consumer, self.s3, self.batch_size = consumer, s3, batch_size
        self.buf = []

    def run(self):
        for msg in self.consumer:
            self.buf.append(transform(msg))
            self.consumer.commit(msg.offset)
            if len(self.buf) >= self.batch_size:
                self.s3.put(key(), self.buf)
                self.buf = []
''',
    "tests/test_api.py": '''import pytest

@pytest.fixture
def client(tmp_path):
    app = create_app(upload_dir=tmp_path)
    with app.test_client() as c:
        yield c

def test_upload(client):
    r = client.post("/upload", data={"file": big_file()}, timeout=5)
    assert r.status_code == 201
''',
    "metrics.go": '''package metrics

var requests int

func Inc() { requests++ }
func Get() int { return requests }
''',
    "parser/json.py": '''def parse(text: str):
    """Parse a JSON document. Returns dict/list/str/int/float/bool/None."""
    p = _Parser(text)
    v = p.value()
    p.skip_ws()
    if p.i != len(text):
        raise ValueError("trailing data")
    return v
''',
    "src/scheduler.ts": '''export function schedule(jobs: Job[], now: Date): Job[] {
  return jobs.filter(j => j.runAt <= now).sort((a, b) => a.priority - b.priority);
}
''',
    # ---- tlaplus-model ----
    "coordinator.py": '''class Coordinator:
    def commit(self, txid, participants):
        votes = [p.prepare(txid) for p in participants]
        decision = "commit" if all(v == "yes" for v in votes) else "abort"
        self.log.write(txid, decision)
        for p in participants:
            p.finish(txid, decision)
''',
    "participant.py": '''class Participant:
    def prepare(self, txid):
        ok = self.store.can_apply(txid)
        self.log.write(txid, "prepared" if ok else "no")
        return "yes" if ok else "no"

    def finish(self, txid, decision):
        if decision == "commit":
            self.store.apply(txid)
        self.log.write(txid, decision)
''',
    "specs/Ledger.tla": '''---- MODULE Ledger ----
EXTENDS Naturals
VARIABLES balance
Init == balance = 0
Withdraw == balance' = balance - 1
Credit == balance' = balance + 1
Next == Withdraw \\/ Credit
====
''',
    "specs/raft/Raft.tla": '''---- MODULE Raft ----
EXTENDS Naturals, Sequences, FiniteSets
CONSTANTS Server, MaxTerm
VARIABLES currentTerm, state, votedFor, log, commitIndex, messages
\\* 5 servers, unbounded messages bag, MaxTerm = 6
====
''',
    "specs/raft/MC.cfg": "CONSTANTS Server = {s1, s2, s3, s4, s5}\n  MaxTerm = 6\nINIT Init\nNEXT Next\nINVARIANT ElectionSafety\n",
    "saga/orchestrator.py": '''class OrderSaga:
    steps = [("reserve", "release"), ("charge", "refund"), ("ship", "cancel_shipment")]

    def run(self, order):
        done = []
        for action, compensate in self.steps:
            try:
                retry(lambda: getattr(self.svc, action)(order), attempts=3)
                done.append(compensate)
            except Exception:
                for c in reversed(done):
                    retry(lambda: getattr(self.svc, c)(order), attempts=3)
                raise
''',
    "logs/events.ndjson": '{"t":1,"node":"a","ev":"acquire","lease":7}\n{"t":2,"node":"b","ev":"acquire","lease":8}\n{"t":3,"node":"a","ev":"commit","lease":7}\n',
    "crdt/counter.ts": '''export type GCounter = Record<string, number>;
export function merge(a: GCounter, b: GCounter): GCounter {
  const out: GCounter = { ...a };
  for (const [k, v] of Object.entries(b)) out[k] = (out[k] ?? 0) + v;
  return out;
}
''',
    "utils/retry.py": '''def retry(fn, attempts=3, delay=0.1):
    for i in range(attempts):
        try:
            return fn()
        except Exception:
            if i == attempts - 1:
                raise
            time.sleep(delay * 2 ** i)
''',
    "cmd/server/main.go": '''package main

func (s *Server) transfer(a, b *Account, amt int) {
	a.mu.Lock()
	defer a.mu.Unlock()
	b.mu.Lock() // line 88: race detector / deadlock report points here
	defer b.mu.Unlock()
	a.bal -= amt
	b.bal += amt
}
''',
    "models/permissions.als": '''sig User {}
sig File { owner: one User, readers: set User }
fact { all f: File | f.owner in f.readers }
assert OwnerCanRead { all f: File | f.owner in f.readers }
check OwnerCanRead for 5
''',
    # ---- lean-model ----
    "lib/intervals.py": '''def merge(intervals):
    out = []
    for s, e in sorted(intervals):
        if out and s < out[-1][1]:
            out[-1] = (out[-1][0], max(out[-1][1], e))
        else:
            out.append((s, e))
    return out
''',
    "scheduler/topo.rs": '''pub fn topo(n: usize, edges: &[(usize, usize)]) -> Vec<usize> {
    let mut indeg = vec![0; n];
    for &(_, b) in edges { indeg[b] += 1; }
    let mut q: Vec<usize> = (0..n).filter(|&i| indeg[i] == 0).collect();
    let mut out = vec![];
    while let Some(v) = q.pop() {
        out.push(v);
        for &(a, b) in edges { if a == v { indeg[b] -= 1; if indeg[b] == 0 { q.push(b); } } }
    }
    out
}
''',
    "pricing/PricingEngine.java": '''public final class PricingEngine {
  public long price(Cart cart, Customer c) {
    long total = cart.subtotalCents();
    if (c.isMember()) total -= total / 10;
    if (cart.items() >= 5) total -= 500;
    return Math.max(total, 0);
  }
}
''',
    "webhooks/dispatcher.py": '''async def dispatch(event, endpoint, store):
    for attempt in range(5):
        try:
            await post(endpoint.url, event.body, timeout=10)
            await store.mark_delivered(event.id)
            return
        except TimeoutError:
            await asyncio.sleep(2 ** attempt)
''',
    "lib/batch.py": '''def batches(items, size):
    buf = []
    for x in items:
        buf.append(x)
        if len(buf) == size:
            yield buf
            buf = []
''',
    "formal/lean/lakefile.toml": 'name = "Formal"\ndefaultTargets = ["Formal"]\n\n[[lean_lib]]\nname = "Formal"\n',
    "formal/lean/lean-toolchain": "leanprover/lean4:v4.34.0\n",
    "formal/lean/Formal/Scheduler.lean": '''inductive PC | idle | awaiting (k : Nat) | done

structure S where
  seen : List Nat
  pcs : List PC

def Inv (s : S) : Prop := ∀ k, PC.awaiting k ∈ s.pcs → k ∈ s.seen

theorem inv_step (s t : S) (h : Inv s) (hs : Step s t) : Inv t := by
  cases hs with
  | dispatch => grind   -- fails: goal has an awaiting task whose key is not in seen
  | finish => grind
''',
    "formal/lean/Formal/Certify.lean": '''def allowed : List (Nat × Nat) := [(0, 1), (1, 2), (2, 3)]

theorem table_closed : ∀ p ∈ allowed, p.1 < p.2 := by native_decide
''',
    "src/graph.rs": '''pub fn neighbors<'a>(g: &'a Graph, v: usize) -> impl Iterator<Item = &'a usize> {
    let adj = &g.adj[v];
    adj.iter().filter(|w| g.alive[**w])
}
''',
    "parser/Combinators.hs": '''newtype Parser a = Parser { runParser :: String -> Maybe (a, String) }

instance Functor Parser where
  fmap f (Parser p) = Parser $ \\s -> fmap (\\(a, r) -> (f a, r)) (p s)
''',
    # ---- proof-simplify ----
    "worker/lease.go": '''func (w *Worker) complete(job *Job, result []byte) error {
	w.mu.Lock()
	defer w.mu.Unlock()
	if job.Owner != w.ID { // defensive
		return ErrNotOwner
	}
	cur, _ := w.store.Get(job.ID)
	if cur.Owner != w.ID || cur.Attempt != job.Attempt { // double check
		return ErrNotOwner
	}
	return w.store.CompareAndSetDone(job.ID, w.ID, job.Attempt, result)
}
''',
    "formal/job-lease/JobLease.tla": '''---- MODULE JobLease ----
EXTENDS Naturals
CONSTANTS Workers
VARIABLES owner, attempt, status
\\* Checked: DoneIsFinal, SingleCommit with CAS fencing on (owner, attempt). TLC passes.
====
''',
    "cache/warmer.py": '''class CacheWarmer:
    def __init__(self):
        self._lock = threading.Lock()

    def refresh(self):
        with self._lock:
            self.cache.replace(self.loader.load_all())
''',
    "formal/cache/Warmer.tla": '''---- MODULE Warmer ----
\\* Only the scheduler thread calls Refresh; proven: at most one Refresh in flight.
====
''',
    "orders/service.py": '''def cancel_order(db, order_id):
    with db.transaction():
        row = db.query("SELECT status FROM orders WHERE id=%s FOR UPDATE", order_id)
        if row.status not in ("pending", "queued"):
            return False
        n = db.execute("UPDATE orders SET status='cancelled' WHERE id=%s AND status IN ('pending','queued')", order_id)
        if n == 0:
            return False
        after = db.query("SELECT status FROM orders WHERE id=%s", order_id)
        assert after.status == "cancelled"
        return True
''',
    "orders/status.py": '''class OrderStatus(enum.Enum):
    PENDING = "pending"
    QUEUED = "queued"
    PAID = "paid"
    CANCELLED = "cancelled"

TRANSITIONS = {("pending", "queued"), ("queued", "pending"), ("pending", "paid"), ("queued", "paid")}
''',
    "formal/orders/Orders.lean": '''-- Proven: pending and queued have identical outgoing transitions and invariants.
theorem pending_queued_bisim : True := trivial
''',
    "jobs/claim.py": '''def complete(job, result):
    if job.status == "CLAIMED" and job.claimed_by is None:
        raise RuntimeError("corrupt job")
    if job.claimed_by is not None and job.status != "CLAIMED":
        raise RuntimeError("corrupt job")
    job.result = result
''',
    "sync/replicator.ts": '''export async function replicate(batch: Change[], peer: Peer) {
  for (let i = 0; i < 5; i++) {
    const r = await peer.send(batch).catch(e => ({ ok: false, err: e }));
    if (r.ok) return;
    if (r.err?.code === "CONFLICT" && batch.length === 0) return; // can this happen?
    if (r.err?.code === "STALE" && !peer.connected) await peer.reconnect();
    else if (r.err?.code === "STALE") throw new Error("stale while connected");
    await sleep(100 * 2 ** i);
  }
}
''',
    "webhooks/handler.py": '''async def handle(event, db, psp):
    if not await db.claim(event.id):          # dedup claim
        return 200
    await psp.capture(event.payment_id, idempotency_key=event.id)
    await db.mark_done(event.id)
    return 200
''',
    "migrations/apply.py": '''def apply_migration(db, m):
    with db.lock("migrations"):
        if db.applied(m.version):
            return  # already_applied guard
        db.run(m.sql)
        db.record(m.version)
''',
    "formal/migrations/Properties.lean": '''-- Proven: apply_migration is only called with versions not yet in `applied`.
theorem called_only_when_unapplied : True := trivial
''',
    "api/handlers.go": '''func GetUser(w http.ResponseWriter, r *http.Request) {
	u, err := store.User(r.Context(), chi.URLParam(r, "id"))
	if err != nil {
		log.Printf("get user: %v", err)
		http.Error(w, "internal", 500)
		return
	}
	json.NewEncoder(w).Encode(u)
}
''',
    "pool/ConnectionPool.java": '''public final class ConnectionPool {
  private final Object lock = new Object();
  private final Object statsLock = new Object();
  public Connection acquire() throws InterruptedException {
    synchronized (lock) { while (free.isEmpty()) lock.wait(); return free.pop(); }
  }
}
''',
    "README.md": "# acme-platform\n\nMonorepo: services/, controllers/, pipeline/, orders/, webhooks/, jobs/, formal/.\n",
}


def main(dest: str, claude_dir: bool = True) -> None:
    root = pathlib.Path(dest)
    if claude_dir:  # skill-creator's run_eval discovers the project root by .claude/
        (root / ".claude").mkdir(parents=True, exist_ok=True)
    for rel, text in FILES.items():
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)
    print(f"wrote {len(FILES)} stub files under {root}")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--no-claude-dir"]
    main(args[0] if args else "trigger-root", claude_dir="--no-claude-dir" not in sys.argv)

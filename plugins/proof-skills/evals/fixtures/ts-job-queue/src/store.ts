// Job table. In production this is Postgres (each method is one SQL statement,
// executed atomically). Here it is an in-memory implementation with the same semantics.
export type Status = "pending" | "running" | "done";
export interface Job {
  id: string;
  status: Status;
  owner?: string;
  leaseUntil?: number;
  result?: string;
}

export class JobStore {
  private jobs = new Map<string, Job>();

  add(id: string): void {
    this.jobs.set(id, { id, status: "pending" });
  }

  // UPDATE jobs SET status='running', owner=$1, lease_until=$2+ttl
  // WHERE id = (SELECT id FROM jobs WHERE status='pending'
  //             OR (status='running' AND lease_until < $2) LIMIT 1) RETURNING *
  claim(workerId: string, now: number, ttlMs: number): Job | undefined {
    for (const job of this.jobs.values()) {
      const expired = job.status === "running" && (job.leaseUntil ?? 0) < now;
      if (job.status === "pending" || expired) {
        job.status = "running";
        job.owner = workerId;
        job.leaseUntil = now + ttlMs;
        return { ...job };
      }
    }
    return undefined;
  }

  // UPDATE jobs SET status='done', result=$2 WHERE id=$1
  complete(jobId: string, workerId: string, result: string): void {
    const job = this.jobs.get(jobId);
    if (!job) throw new Error(`no job ${jobId}`);
    job.status = "done";
    job.result = result;
  }

  get(id: string): Job | undefined {
    const j = this.jobs.get(id);
    return j && { ...j };
  }
}

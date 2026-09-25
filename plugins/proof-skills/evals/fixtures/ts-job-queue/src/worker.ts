import { JobStore, Job } from "./store";

export interface Clock { now(): number }
export type Processor = (job: Job) => Promise<string>;   // may take longer than the lease (GC, slow API)

export class Worker {
  constructor(
    private id: string,
    private store: JobStore,
    private clock: Clock,
    private process: Processor,
    private ttlMs = 30_000,
  ) {}

  async runOnce(): Promise<boolean> {
    const job = this.store.claim(this.id, this.clock.now(), this.ttlMs);
    if (!job) return false;
    const result = await this.process(job);        // side effects happen here (emails, charges)
    this.store.complete(job.id, this.id, result);
    return true;
  }
}

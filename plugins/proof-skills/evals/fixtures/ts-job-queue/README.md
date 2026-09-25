# job-queue

Lease-based job queue. Workers claim a job with a 30s lease; if a worker dies, the lease
expires and another worker picks the job up. `src/store.ts` is the table, `src/worker.ts`
the worker loop. Many workers run concurrently across machines.

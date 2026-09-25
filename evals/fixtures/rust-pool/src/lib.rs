//! Bounded connection pool shared by request-handler threads.
//!
//! Invariants we rely on in production:
//!   * never more than `max` connections checked out at once (the DB has a hard limit), and
//!   * a thread blocked in `acquire` is woken when a connection is released.
use std::sync::{Condvar, Mutex};

#[derive(Debug)]
pub struct Conn {
    pub id: usize,
}

pub struct Pool {
    max: usize,
    in_use: Mutex<usize>,
    idle: Mutex<Vec<Conn>>,
    available: Condvar,
    next_id: Mutex<usize>,
}

impl Pool {
    pub fn new(max: usize) -> Self {
        Pool {
            max,
            in_use: Mutex::new(0),
            idle: Mutex::new(Vec::new()),
            available: Condvar::new(),
            next_id: Mutex::new(0),
        }
    }

    pub fn in_use(&self) -> usize {
        *self.in_use.lock().unwrap()
    }

    /// Check out a connection, blocking while the pool is exhausted.
    pub fn acquire(&self) -> Conn {
        loop {
            let n = *self.in_use.lock().unwrap();
            if n < self.max {
                *self.in_use.lock().unwrap() += 1;
                if let Some(c) = self.idle.lock().unwrap().pop() {
                    return c;
                }
                let mut id = self.next_id.lock().unwrap();
                *id += 1;
                return Conn { id: *id };
            }
            let guard = self.in_use.lock().unwrap();
            let _guard = self.available.wait(guard).unwrap();
        }
    }

    /// Return a connection to the pool and wake one waiter.
    pub fn release(&self, c: Conn) {
        self.idle.lock().unwrap().push(c);
        self.available.notify_one();
        *self.in_use.lock().unwrap() -= 1;
    }
}

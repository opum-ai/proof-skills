// Package dag runs build steps in dependency order with bounded parallelism.
package dag

import "sync"

type State int

const (
	Pending State = iota
	Running
	Done
)

type Executor struct {
	mu      sync.Mutex
	deps    map[string][]string // step -> steps it depends on
	state   map[string]State
	workers int
	running int
	run     func(step string) // executes the step; called without the lock held
	wg      sync.WaitGroup
}

func New(deps map[string][]string, workers int, run func(string)) *Executor {
	st := make(map[string]State)
	for s, ds := range deps {
		st[s] = Pending
		for _, d := range ds {
			if _, ok := st[d]; !ok {
				st[d] = Pending
			}
		}
	}
	return &Executor{deps: deps, state: st, workers: workers, run: run}
}

// ready reports whether every dependency of step has been scheduled.
func (e *Executor) ready(step string) bool {
	for _, d := range e.deps[step] {
		if e.state[d] == Pending {
			return false
		}
	}
	return true
}

// dispatch starts every ready step while worker slots are free. Caller holds e.mu.
func (e *Executor) dispatch() {
	for step, st := range e.state {
		if e.running >= e.workers {
			return
		}
		if st == Pending && e.ready(step) {
			e.state[step] = Running
			e.running++
			e.wg.Add(1)
			go e.exec(step)
		}
	}
}

func (e *Executor) exec(step string) {
	defer e.wg.Done()
	e.run(step)
	e.mu.Lock()
	e.state[step] = Done
	e.running--
	e.dispatch()
	e.mu.Unlock()
}

// Run executes all steps and returns when they are finished.
func (e *Executor) Run() {
	e.mu.Lock()
	e.dispatch()
	e.mu.Unlock()
	e.wg.Wait()
}

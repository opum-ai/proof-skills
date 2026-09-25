package dag

import (
	"sync"
	"testing"
)

func TestChainRunsInOrder(t *testing.T) {
	var mu sync.Mutex
	var order []string
	e := New(map[string][]string{"b": {"a"}, "c": {"b"}}, 1, func(s string) {
		mu.Lock()
		order = append(order, s)
		mu.Unlock()
	})
	e.Run()
	if len(order) != 3 || order[0] != "a" || order[1] != "b" || order[2] != "c" {
		t.Fatalf("got %v", order)
	}
}

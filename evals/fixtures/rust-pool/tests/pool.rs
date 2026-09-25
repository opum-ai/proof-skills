use pool::Pool;

#[test]
fn acquire_and_release() {
    let p = Pool::new(2);
    let a = p.acquire();
    let b = p.acquire();
    assert_eq!(p.in_use(), 2);
    p.release(a);
    p.release(b);
    assert_eq!(p.in_use(), 0);
}

#[test]
fn reuses_idle_connections() {
    let p = Pool::new(1);
    let a = p.acquire();
    let id = a.id;
    p.release(a);
    assert_eq!(p.acquire().id, id);
}

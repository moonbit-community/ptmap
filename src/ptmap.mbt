/// Patricia Tree Map implementation for MoonBit
///
/// Maps over integers implemented as Patricia trees.
///
/// This implementation follows "Fast Mergeable Integer Maps" by Chris Okasaki
/// and Andrew Gill (Workshop on ML, 1998), with the bug fix described in
/// "QuickChecking Patricia Trees" by Jan Midtgaard (2017).
///
/// These are little-endian Patricia trees, so there is no efficient ordering
/// of keys within the structure. Consequently:
/// - min/max_binding, find_first/last are rather inefficient (linear)
/// - iter, fold do not iterate in key order
/// - bindings is not sorted by keys

///| Key type for the map (integer)
pub typealias Int as Key

///| Patricia tree map data structure
pub enum T[V] {
  /// Empty map
  Empty
  /// Leaf node containing a key-value pair
  Leaf(Key, V)
  /// Branch node with prefix, mask, and left/right subtrees
  Branch(Int, Int, T[V], T[V])
} derive(Show, Eq)

///| Create an empty map
pub fn[V] T::empty() -> T[V] {
  Empty
}

///| Check if the map is empty
pub fn[V] is_empty(self : T[V]) -> Bool {
  match self {
    Empty => true
    _ => false
  }
}

///| Test if a bit is zero in a key given a mask
fn zero_bit(k : Int, m : Int) -> Bool {
  (k & m) == 0
}

///| Get the lowest bit of an integer
fn lowest_bit(x : Int) -> Int {
  x & -x
}

///| Calculate the branching bit between two prefixes
fn branching_bit(p0 : Int, p1 : Int) -> Int {
  lowest_bit(p0 ^ p1)
}

///| Apply mask to get the prefix
fn mask(p : Int, m : Int) -> Int {
  p & (m - 1)
}

///| Check if a key matches a prefix with given mask
fn match_prefix(k : Int, p : Int, m : Int) -> Bool {
  mask(k, m) == p
}

///| Join two trees with different prefixes
fn[V] join(p0 : Int, t0 : T[V], p1 : Int, t1 : T[V]) -> T[V] {
  let m = branching_bit(p0, p1)
  if zero_bit(p0, m) {
    Branch(mask(p0, m), m, t0, t1)
  } else {
    Branch(mask(p0, m), m, t1, t0)
  }
}

///| Smart constructor for branch nodes that handles empty subtrees
fn[V] branch(p : Int, m : Int, t0 : T[V], t1 : T[V]) -> T[V] {
  match (t0, t1) {
    (Empty, t) => t
    (t, Empty) => t
    (_, _) => Branch(p, m, t0, t1)
  }
}

///| Check if a key is present in the map
pub fn[V] mem(self : T[V], k : Key) -> Bool {
  fn go(t : T[V]) -> Bool {
    match t {
      Empty => false
      Leaf(j, _) => k == j
      Branch(_, m, l, r) => go(if zero_bit(k, m) { l } else { r })
    }
  }

  go(self)
}

///| Add a key-value binding to the map
pub fn[V] add(self : T[V], k : Key, v : V) -> T[V] {
  fn ins(t : T[V]) -> T[V] {
    match t {
      Empty => Leaf(k, v)
      Leaf(j, _) => if j == k { Leaf(k, v) } else { join(k, Leaf(k, v), j, t) }
      Branch(p, m, t0, t1) =>
        if match_prefix(k, p, m) {
          if zero_bit(k, m) {
            Branch(p, m, ins(t0), t1)
          } else {
            Branch(p, m, t0, ins(t1))
          }
        } else {
          join(k, Leaf(k, v), p, t)
        }
    }
  }

  ins(self)
}

///| Create a singleton map with one key-value pair
pub fn[V] T::singleton(k : Key, v : V) -> T[V] {
  T::empty().add(k, v)
}

///| Remove a key from the map
pub fn[V] remove(self : T[V], k : Key) -> T[V] {
  fn rmv(t : T[V]) -> T[V] {
    match t {
      Empty => Empty
      Leaf(j, _) => if k == j { Empty } else { t }
      Branch(p, m, t0, t1) =>
        if match_prefix(k, p, m) {
          if zero_bit(k, m) {
            branch(p, m, rmv(t0), t1)
          } else {
            branch(p, m, t0, rmv(t1))
          }
        } else {
          t
        }
    }
  }

  rmv(self)
}

///| Count the number of key-value pairs in the map
pub fn[V] cardinal(self : T[V]) -> Int {
  fn count(t : T[V]) -> Int {
    match t {
      Empty => 0
      Leaf(_, _) => 1
      Branch(_, _, t0, t1) => count(t0) + count(t1)
    }
  }

  count(self)
}

///| Find the value associated with a key
pub fn[V] find(self : T[V], k : Key) -> V {
  fn go(t : T[V]) -> V {
    match t {
      Empty => abort("Key not found")
      Leaf(j, x) => if k == j { x } else { abort("Key not found") }
      Branch(_, m, l, r) => go(if zero_bit(k, m) { l } else { r })
    }
  }

  go(self)
}

///| Find the value associated with a key, returning None if not found
pub fn[V] find_opt(self : T[V], k : Key) -> V? {
  fn go(t : T[V]) -> V? {
    match t {
      Empty => None
      Leaf(j, x) => if k == j { Some(x) } else { None }
      Branch(_, m, l, r) => go(if zero_bit(k, m) { l } else { r })
    }
  }

  go(self)
}

///| Update the value for a given key using a function
pub fn[V] update(self : T[V], k : Key, f : (V?) -> V?) -> T[V] {
  match f(self.find_opt(k)) {
    None => self.remove(k)
    Some(z) => self.add(k, z)
  }
}

///| Find the first key-value pair satisfying a predicate
pub fn[V] find_first(self : T[V], predicate : (Key) -> Bool) -> (Key, V) {
  fn find_first_opt_helper(t : T[V]) -> (Key, V)? {
    match t {
      Empty => None
      Leaf(j, x) => if predicate(j) { Some((j, x)) } else { None }
      Branch(_, _, l, r) =>
        match (find_first_opt_helper(l), find_first_opt_helper(r)) {
          (Some((lk, lv)), Some((rk, rv))) =>
            if lk < rk {
              Some((lk, lv))
            } else {
              Some((rk, rv))
            }
          (Some(v), None) | (None, Some(v)) => Some(v)
          (None, None) => None
        }
    }
  }

  match find_first_opt_helper(self) {
    Some(result) => result
    None => abort("No element satisfies the predicate")
  }
}

///| Find the first key-value pair satisfying a predicate, returning None if none found
pub fn[V] find_first_opt(self : T[V], predicate : (Key) -> Bool) -> (Key, V)? {
  fn go(t : T[V]) -> (Key, V)? {
    match t {
      Empty => None
      Leaf(j, x) => if predicate(j) { Some((j, x)) } else { None }
      Branch(_, _, l, r) =>
        match (go(l), go(r)) {
          (Some((lk, lv)), Some((rk, rv))) =>
            if lk < rk {
              Some((lk, lv))
            } else {
              Some((rk, rv))
            }
          (Some(v), None) | (None, Some(v)) => Some(v)
          (None, None) => None
        }
    }
  }

  go(self)
}

///| Find the last key-value pair satisfying a predicate
pub fn[V] find_last(self : T[V], predicate : (Key) -> Bool) -> (Key, V) {
  fn find_last_opt_helper(t : T[V]) -> (Key, V)? {
    match t {
      Empty => None
      Leaf(j, x) => if predicate(j) { Some((j, x)) } else { None }
      Branch(_, _, l, r) =>
        match (find_last_opt_helper(l), find_last_opt_helper(r)) {
          (Some((lk, lv)), Some((rk, rv))) =>
            if lk > rk {
              Some((lk, lv))
            } else {
              Some((rk, rv))
            }
          (Some(v), None) | (None, Some(v)) => Some(v)
          (None, None) => None
        }
    }
  }

  match find_last_opt_helper(self) {
    Some(result) => result
    None => abort("No element satisfies the predicate")
  }
}

///| Find the last key-value pair satisfying a predicate, returning None if none found
pub fn[V] find_last_opt(self : T[V], predicate : (Key) -> Bool) -> (Key, V)? {
  fn go(t : T[V]) -> (Key, V)? {
    match t {
      Empty => None
      Leaf(j, x) => if predicate(j) { Some((j, x)) } else { None }
      Branch(_, _, l, r) =>
        match (go(l), go(r)) {
          (Some((lk, lv)), Some((rk, rv))) =>
            if lk > rk {
              Some((lk, lv))
            } else {
              Some((rk, rv))
            }
          (Some(v), None) | (None, Some(v)) => Some(v)
          (None, None) => None
        }
    }
  }

  go(self)
}

///| Iterate over all key-value pairs in the map
pub fn[V] iter(self : T[V], f : (Key, V) -> Unit) -> Unit {
  fn go(t : T[V]) -> Unit {
    match t {
      Empty => ()
      Leaf(k, x) => f(k, x)
      Branch(_, _, t0, t1) => {
        go(t0)
        go(t1)
      }
    }
  }

  go(self)
}

///| Map a function over all values in the map
pub fn[V, U] map(self : T[V], f : (V) -> U) -> T[U] {
  fn go(t : T[V]) -> T[U] {
    match t {
      Empty => Empty
      Leaf(k, x) => Leaf(k, f(x))
      Branch(p, m, t0, t1) => Branch(p, m, go(t0), go(t1))
    }
  }

  go(self)
}

///| Map a function over all key-value pairs in the map
pub fn[V, U] mapi(self : T[V], f : (Key, V) -> U) -> T[U] {
  fn go(t : T[V]) -> T[U] {
    match t {
      Empty => Empty
      Leaf(k, x) => Leaf(k, f(k, x))
      Branch(p, m, t0, t1) => Branch(p, m, go(t0), go(t1))
    }
  }

  go(self)
}

///| Fold over all key-value pairs in the map
pub fn[V, Acc] fold(self : T[V], f : (Key, V, Acc) -> Acc, init : Acc) -> Acc {
  fn go(t : T[V], acc : Acc) -> Acc {
    match t {
      Empty => acc
      Leaf(k, x) => f(k, x, acc)
      Branch(_, _, t0, t1) => go(t0, go(t1, acc))
    }
  }

  go(self, init)
}

///| Check if all key-value pairs satisfy a predicate
pub fn[V] for_all(self : T[V], predicate : (Key, V) -> Bool) -> Bool {
  fn go(t : T[V]) -> Bool {
    match t {
      Empty => true
      Leaf(k, v) => predicate(k, v)
      Branch(_, _, t0, t1) => go(t0) && go(t1)
    }
  }

  go(self)
}

///| Check if any key-value pair satisfies a predicate
pub fn[V] exists(self : T[V], predicate : (Key, V) -> Bool) -> Bool {
  fn go(t : T[V]) -> Bool {
    match t {
      Empty => false
      Leaf(k, v) => predicate(k, v)
      Branch(_, _, t0, t1) => go(t0) || go(t1)
    }
  }

  go(self)
}

///| Filter the map to include only key-value pairs satisfying a predicate
pub fn[V] filter(self : T[V], predicate : (Key, V) -> Bool) -> T[V] {
  fn go(t : T[V]) -> T[V] {
    match t {
      Empty => Empty
      Leaf(k, v) => if predicate(k, v) { t } else { Empty }
      Branch(p, m, t0, t1) => branch(p, m, go(t0), go(t1))
    }
  }

  go(self)
}

///| Filter and map over the map, keeping only successful transformations
pub fn[V, U] filter_map(self : T[V], f : (Key, V) -> U?) -> T[U] {
  fn go(t : T[V]) -> T[U] {
    match t {
      Empty => Empty
      Leaf(k, v) =>
        match f(k, v) {
          Some(v_new) => Leaf(k, v_new)
          None => Empty
        }
      Branch(p, m, t0, t1) => branch(p, m, go(t0), go(t1))
    }
  }

  go(self)
}

///| Partition the map into two maps based on a predicate
pub fn[V] partition(self : T[V], predicate : (Key, V) -> Bool) -> (T[V], T[V]) {
  fn part(acc : (T[V], T[V]), t : T[V]) -> (T[V], T[V]) {
    let (true_map, false_map) = acc
    match t {
      Empty => acc
      Leaf(k, v) =>
        if predicate(k, v) {
          (true_map.add(k, v), false_map)
        } else {
          (true_map, false_map.add(k, v))
        }
      Branch(_, _, t0, t1) => part(part(acc, t0), t1)
    }
  }

  part((T::empty(), T::empty()), self)
}

///| Helper function for unsigned comparison (needed for union algorithm)
fn unsigned_lt(n : Int, m : Int) -> Bool {
  n >= 0 && (m < 0 || n < m)
}

///| Union two maps with a combining function for conflicting keys
pub fn[V] union(self : T[V], other : T[V], f : (Key, V, V) -> V?) -> T[V] {
  fn union_impl(s : T[V], t : T[V]) -> T[V] {
    match (s, t) {
      (Empty, t) => t
      (s, Empty) => s
      (Leaf(k, v1), t) =>
        t.update(k, fn(opt_v2) {
          match opt_v2 {
            None => Some(v1)
            Some(v2) => f(k, v1, v2)
          }
        })
      (s, Leaf(k, v2)) =>
        s.update(k, fn(opt_v1) {
          match opt_v1 {
            None => Some(v2)
            Some(v1) => f(k, v1, v2)
          }
        })
      (Branch(p, m, s0, s1), Branch(q, n, t0, t1)) =>
        if m == n && match_prefix(q, p, m) {
          // The trees have the same prefix. Merge the subtrees.
          branch(p, m, union_impl(s0, t0), union_impl(s1, t1))
        } else if unsigned_lt(m, n) && match_prefix(q, p, m) {
          // q contains p. Merge t with a subtree of s.
          if zero_bit(q, m) {
            branch(p, m, union_impl(s0, t), s1)
          } else {
            branch(p, m, s0, union_impl(s1, t))
          }
        } else if unsigned_lt(n, m) && match_prefix(p, q, n) {
          // p contains q. Merge s with a subtree of t.
          if zero_bit(p, n) {
            branch(q, n, union_impl(s, t0), t1)
          } else {
            branch(q, n, t0, union_impl(s, t1))
          }
        } else {
          // The prefixes disagree.
          join(p, s, q, t)
        }
    }
  }

  union_impl(self, other)
}

///| Merge two maps with a three-way merge function
pub fn[V, U, W] merge(
  self : T[V],
  other : T[U],
  f : (Key, V?, U?) -> W?,
) -> T[W] {
  let add_result = fn(m : T[W], k : Key, opt_w : W?) -> T[W] {
    match opt_w {
      None => m
      Some(w) => m.add(k, w)
    }
  }

  // First consider all bindings in self
  let m = self.fold(
    fn(k1, v1, acc) { add_result(acc, k1, f(k1, Some(v1), other.find_opt(k1))) },
    T::empty(),
  )

  // Then bindings in other that are not in self
  other.fold(
    fn(k2, v2, acc) {
      if self.mem(k2) {
        acc
      } else {
        add_result(acc, k2, f(k2, None, Some(v2)))
      }
    },
    m,
  )
}

///| Compare two maps with a value comparison function
pub fn[V] compare(self : T[V], other : T[V], cmp : (V, V) -> Int) -> Int {
  fn compare_aux(t1 : T[V], t2 : T[V]) -> Int {
    match (t1, t2) {
      (Empty, Empty) => 0
      (Empty, _) => -1
      (_, Empty) => 1
      (Leaf(k1, x1), Leaf(k2, x2)) => {
        let c = k1.compare(k2)
        if c != 0 {
          c
        } else {
          cmp(x1, x2)
        }
      }
      (Leaf(_), Branch(_, _, _, _)) => -1
      (Branch(_, _, _, _), Leaf(_)) => 1
      (Branch(p1, m1, l1, r1), Branch(p2, m2, l2, r2)) => {
        let c = p1.compare(p2)
        if c != 0 {
          c
        } else {
          let c = m1.compare(m2)
          if c != 0 {
            c
          } else {
            let c = compare_aux(l1, l2)
            if c != 0 {
              c
            } else {
              compare_aux(r1, r2)
            }
          }
        }
      }
    }
  }

  compare_aux(self, other)
}

///| Check if two maps are equal with a value equality function
pub fn[V] equal(self : T[V], other : T[V], eq : (V, V) -> Bool) -> Bool {
  fn equal_aux(t1 : T[V], t2 : T[V]) -> Bool {
    match (t1, t2) {
      (Empty, Empty) => true
      (Leaf(k1, x1), Leaf(k2, x2)) => k1 == k2 && eq(x1, x2)
      (Branch(p1, m1, l1, r1), Branch(p2, m2, l2, r2)) =>
        p1 == p2 && m1 == m2 && equal_aux(l1, l2) && equal_aux(r1, r2)
      (_, _) => false
    }
  }

  equal_aux(self, other)
}

///| Find the minimum key-value binding in the map
pub fn[V] min_binding(self : T[V]) -> (Key, V) {
  fn go(t : T[V]) -> (Key, V) {
    match t {
      Empty => abort("Map is empty")
      Leaf(k, v) => (k, v)
      Branch(_, _, s, t) => {
        let (ks, vs) = go(s)
        let (kt, vt) = go(t)
        if ks < kt {
          (ks, vs)
        } else {
          (kt, vt)
        }
      }
    }
  }

  go(self)
}

///| Find the minimum key-value binding in the map, returning None if empty
pub fn[V] min_binding_opt(self : T[V]) -> (Key, V)? {
  fn go(t : T[V]) -> (Key, V)? {
    match t {
      Empty => None
      Leaf(k, v) => Some((k, v))
      Branch(_, _, s, t) =>
        match (go(s), go(t)) {
          (None, None) => None
          (None, bt) => bt
          (bs, None) => bs
          (Some((ks, vs)), Some((kt, vt))) =>
            if ks < kt {
              Some((ks, vs))
            } else {
              Some((kt, vt))
            }
        }
    }
  }

  go(self)
}

///| Find the maximum key-value binding in the map
pub fn[V] max_binding(self : T[V]) -> (Key, V) {
  fn go(t : T[V]) -> (Key, V) {
    match t {
      Empty => abort("Map is empty")
      Leaf(k, v) => (k, v)
      Branch(_, _, s, t) => {
        let (ks, vs) = go(s)
        let (kt, vt) = go(t)
        if ks > kt {
          (ks, vs)
        } else {
          (kt, vt)
        }
      }
    }
  }

  go(self)
}

///| Find the maximum key-value binding in the map, returning None if empty
pub fn[V] max_binding_opt(self : T[V]) -> (Key, V)? {
  fn go(t : T[V]) -> (Key, V)? {
    match t {
      Empty => None
      Leaf(k, v) => Some((k, v))
      Branch(_, _, s, t) =>
        match (go(s), go(t)) {
          (None, None) => None
          (None, bt) => bt
          (bs, None) => bs
          (Some((ks, vs)), Some((kt, vt))) =>
            if ks > kt {
              Some((ks, vs))
            } else {
              Some((kt, vt))
            }
        }
    }
  }

  go(self)
}

///| Choose an arbitrary key-value pair from the map
pub fn[V] choose(self : T[V]) -> (Key, V) {
  match self {
    Empty => abort("Map is empty")
    Leaf(k, v) => (k, v)
    Branch(_, _, t0, _) => t0.choose() // we know that t0 is non-empty
  }
}

///| Choose an arbitrary key-value pair from the map, returning None if empty
pub fn[V] choose_opt(self : T[V]) -> (Key, V)? {
  match self {
    Empty => None
    Leaf(k, v) => Some((k, v))
    Branch(_, _, t0, _) => t0.choose_opt() // we know that t0 is non-empty
  }
}

///| Split the map at a given key
pub fn[V] split(self : T[V], x : Key) -> (T[V], V?, T[V]) {
  let collect = fn(k : Key, v : V, acc : (T[V], V?, T[V])) -> (T[V], V?, T[V]) {
    let (l, b, r) = acc
    if k < x {
      (l.add(k, v), b, r)
    } else if k > x {
      (l, b, r.add(k, v))
    } else {
      (l, Some(v), r)
    }
  }
  self.fold(collect, (T::empty(), None, T::empty()))
}

///| Get all key-value bindings as a list
pub fn[V] bindings(self : T[V]) -> Array[(Key, V)] {
  let result = []
  self.iter(fn(k, v) { result.push((k, v)) })
  result
}

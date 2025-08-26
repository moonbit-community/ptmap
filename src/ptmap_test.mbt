///
test "basic ptmap functionality" {
  // Test empty map
  let empty : T[Int] = T::empty()
  if not(empty.is_empty()) {
    abort("Empty map should be empty")
  }

  // Test singleton
  let single = T::singleton(1, 100)
  if single.find(1) != 100 {
    abort("Singleton should contain the correct value")
  }

  // Test adding elements
  let mut map : T[String] = T::empty()
  map = map.add(1, "one")
  map = map.add(2, "two")
  if map.cardinal() != 2 {
    abort("Map should have 2 elements")
  }
  if not(map.mem(1)) || not(map.mem(2)) {
    abort("Map should contain both keys")
  }

  // Test find_opt
  match map.find_opt(1) {
    Some(val) => if val != "one" { abort("Wrong value for key 1") }
    None => abort("Key 1 should be found")
  }
  match map.find_opt(99) {
    Some(_) => abort("Key 99 should not be found")
    None => ()
  }

  // Test removal
  map = map.remove(1)
  if map.mem(1) {
    abort("Key 1 should be removed")
  }
  if map.cardinal() != 1 {
    abort("Map should have 1 element after removal")
  }
}
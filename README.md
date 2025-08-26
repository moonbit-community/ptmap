# Patricia Tree Map for MoonBit

[![License: LGPL v2.1](https://img.shields.io/badge/License-LGPL%20v2.1-blue.svg)](https://www.gnu.org/licenses/lgpl-2.1)

A high-performance Patricia Tree Map implementation for MoonBit, providing fast mergeable integer maps.

## Overview

This library implements Patricia trees (also known as PATRICIA - Practical Algorithm to Retrieve Information Coded in Alphanumeric) for integer-keyed maps. Patricia trees are a specialized data structure that provides efficient operations for maps with integer keys.

## Features

- **Fast Operations**: O(log n) complexity for most operations
- **Functional/Persistent**: Operations return new maps without modifying the original
- **Memory Efficient**: Structural sharing between different map versions
- **Comprehensive API**: Full set of map operations including union, merge, filter, fold, etc.
- **Type Safe**: Full MoonBit type safety with generic value types

## Algorithm Background

This implementation follows the paper "Fast Mergeable Integer Maps" by Chris Okasaki and Andrew Gill (Workshop on ML, 1998), with the bug fix described in "QuickChecking Patricia Trees" by Jan Midtgaard (2017).

**Important Note**: These are little-endian Patricia trees, which means:
- No efficient ordering of keys within the structure
- `min_binding`, `max_binding`, `find_first`, `find_last` are O(n) operations
- `iter`, `fold` do **not** iterate in key order
- `bindings` is **not sorted** by keys

## Installation

Add the dependency to your project:

```bash
moon add illusory0x0/ptmap
```

Or manually add it to your `moon.mod.json`:

```json
{
  "deps": {
    "illusory0x0/ptmap": "*"
  }
}
```

## Basic Usage

```moonbit
// Create an empty map
let map = T::empty[String]()

// Add some key-value pairs
let map = map.add(1, "one")
            .add(2, "two")
            .add(3, "three")

// Check if a key exists
if map.mem(2) {
  println("Key 2 exists")
}

// Find a value
match map.find_opt(1) {
  Some(value) => println("Found: \{value}")
  None => println("Key not found")
}

// Remove a key
let map = map.remove(2)

// Get the number of elements
println("Map has \{map.cardinal()} elements")
```

## API Reference

### Core Operations

- `T::empty[V]() -> T[V]` - Create an empty map
- `T::singleton(key, value) -> T[V]` - Create a map with one element
- `add(self, key, value) -> T[V]` - Add a key-value pair
- `remove(self, key) -> T[V]` - Remove a key
- `mem(self, key) -> Bool` - Check if key exists
- `find(self, key) -> V` - Find value (aborts if not found)
- `find_opt(self, key) -> V?` - Find value safely
- `is_empty(self) -> Bool` - Check if map is empty
- `cardinal(self) -> Int` - Get number of elements

### Higher-Order Functions

- `map(self, f) -> T[U]` - Transform all values
- `mapi(self, f) -> T[U]` - Transform with access to keys
- `filter(self, predicate) -> T[V]` - Keep elements matching predicate
- `filter_map(self, f) -> T[U]` - Filter and transform in one step
- `fold(self, f, init) -> Acc` - Reduce to a single value
- `iter(self, f) -> Unit` - Execute function on each element

### Set Operations

- `union(self, other, merge_fn) -> T[V]` - Merge two maps
- `merge(self, other, merge_fn) -> T[W]` - Three-way merge
- `compare(self, other, cmp) -> Int` - Compare two maps
- `equal(self, other, eq) -> Bool` - Test equality

### Utility Functions

- `min_binding(self) -> (Key, V)` - Find minimum key (O(n))
- `max_binding(self) -> (Key, V)` - Find maximum key (O(n))
- `choose(self) -> (Key, V)` - Get arbitrary element
- `split(self, key) -> (T[V], V?, T[V])` - Split at key
- `bindings(self) -> Array[(Key, V)]` - Get all key-value pairs
- `partition(self, predicate) -> (T[V], T[V])` - Split into two maps

## Performance Characteristics

| Operation | Time Complexity | Space Complexity |
|-----------|----------------|-----------------|
| `add` | O(log n) | O(log n) |
| `remove` | O(log n) | O(log n) |
| `find` | O(log n) | O(1) |
| `mem` | O(log n) | O(1) |
| `union` | O(n + m) | O(n + m) |
| `merge` | O(n + m) | O(n + m) |
| `fold` | O(n) | O(1) |
| `map` | O(n) | O(n) |
| `filter` | O(n) | O(k) where k = result size |

## Examples

### Working with Different Value Types

```moonbit
// String values
let names = T::empty[String]()
              .add(1, "Alice")
              .add(2, "Bob")
              .add(3, "Charlie")

// Custom types
struct Person {
  name: String
  age: Int
}

let people = T::empty[Person]()
               .add(1, Person::{ name: "Alice", age: 30 })
               .add(2, Person::{ name: "Bob", age: 25 })
```

### Functional Operations

```moonbit
let numbers = T::empty[Int]()
                .add(1, 10)
                .add(2, 20)
                .add(3, 30)

// Double all values
let doubled = numbers.map(fn(x) { x * 2 })

// Keep only even keys
let evens = numbers.filter(fn(k, _v) { k % 2 == 0 })

// Sum all values
let sum = numbers.fold(fn(_k, v, acc) { acc + v }, 0)

// Check if all values are positive
let all_positive = numbers.for_all(fn(_k, v) { v > 0 })
```

### Merging Maps

```moonbit
let map1 = T::empty[Int]().add(1, 10).add(2, 20)
let map2 = T::empty[Int]().add(2, 200).add(3, 30)

// Union with conflict resolution (keep first value)
let merged = map1.union(map2, fn(_key, v1, _v2) { Some(v1) })

// Three-way merge
let result = map1.merge(map2, fn(_key, opt_v1, opt_v2) {
  match (opt_v1, opt_v2) {
    (Some(a), Some(b)) => Some(a + b)  // Sum if both present
    (Some(a), None) => Some(a)         // Keep if only in first
    (None, Some(b)) => Some(b)         // Keep if only in second
    (None, None) => None               // Skip if in neither
  }
})
```

## Testing

Run the test suite:

```bash
moon test
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the GNU Lesser General Public License v2.1 - see the [LICENSE](LICENSE) file for details.

This follows the same license as the original OCaml implementation to maintain compatibility.

## Original Implementation

This MoonBit implementation is based on the OCaml Patricia Tree Map library by Jean-Christophe Filliatre.

**Original Repository**: [https://github.com/backtracking/ptmap](https://github.com/backtracking/ptmap)

The original OCaml implementation provides the foundation for this MoonBit port, maintaining the same algorithmic approach and API design while adapting to MoonBit's type system and language features.

## Credits

- Original OCaml implementation by Jean-Christophe Filliatre ([ptmap](https://github.com/backtracking/ptmap))
- Based on the paper "Fast Mergeable Integer Maps" by Chris Okasaki and Andrew Gill
- Bug fix from "QuickChecking Patricia Trees" by Jan Midtgaard
- MoonBit port adaptation

## References

- [Original OCaml ptmap repository](https://github.com/backtracking/ptmap) - Source implementation
- [Fast Mergeable Integer Maps](http://www.cs.columbia.edu/~cdo/papers.html#ml98maps) - Original paper
- [QuickChecking Patricia Trees](https://www.janmidtgaard.dk/papers/Midtgaard-al:JFP-2017.pdf) - Bug fix paper
- [MoonBit Language](https://www.moonbitlang.com/) - Target language documentation
# gens

[![Package Version](https://img.shields.io/hexpm/v/gens)](https://hex.pm/packages/gens)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gens/)

Gleam generators and infinite lazy lists!

```sh
gleam add gens
```

### LazyList

They are infinite lists generated from a given formula. The `new` function returns the infinite list of natural numbers that can later be transformed with functions such as `map`, `filter`, or `drop`. Finally, to produce a concrete list from the formula, we call the `take` function.

```gleam
import gleam/int
import gens

pub fn main() -> Nil {
  gens.new()
  |> gens.map(fn(x) { x + 3 })
  |> gens.filter(fn(x) {x % 2 != 0 })
  |> gens.map(int.to_string)
  |> take(5)
  |> echo
  // -> ["3", "5", "7", "9", "11"]
  Nil
}
```

### Generator

Generators produce one or more elements at a time, updating an internal state. The update function can have an end condition, where the generated element will be `None`. This signals to the user that there are no more elements to be generated.

```gleam
import gens
import gleam/option

pub fn main() -> Nil {
  let counter =
    gens.Generator(state: 0, next: fn(c) { option.Some(#(c, c + 1)) })

  let #(nums, counter2) = gens.gen(counter, 5)
  echo nums
  // -> [0, 1, 2, 3, 4]
  echo counter2.state
  // -> 5
  Nil
}
```

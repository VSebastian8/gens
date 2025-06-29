# gens

[![Package Version](https://img.shields.io/hexpm/v/gens)](https://hex.pm/packages/gens)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gens/)

Gleam generators and lazy infinite lists!

```sh
gleam add gens@1
```

### LazyList

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

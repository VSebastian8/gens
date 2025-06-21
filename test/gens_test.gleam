import gens.{filter, gen, map, new}
import gleam/int
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

// Basic test for the default generator and the gen function
pub fn gen_test() {
  assert gen(new(), 0) == []
  assert gen(new(), 1) == [0]
  assert new() |> gen(5) == [0, 1, 2, 3, 4]
}

// Testing the map function for the generator type
pub fn map_test() {
  assert new()
    |> map(fn(x) { x + 3 })
    |> map(int.to_string)
    |> gen(5)
    == ["3", "4", "5", "6", "7"]
}

// Testing the filter function for the generator type
pub fn filter_test() {
  assert new()
    |> filter(fn(x) { x % 2 == 0 })
    |> filter(fn(x) { x != 4 })
    |> gen(5)
    == [0, 2, 6, 8, 10]
}

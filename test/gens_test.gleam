import gens.{drop, filter, gen, list_zip, map, new, next, zip}
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

// Testing the drop function for the generator type
pub fn drop_test() {
  assert new()
    |> drop(0)
    |> gen(1)
    == [0]
  assert new()
    |> drop(1)
    |> gen(1)
    == [1]
  assert new()
    |> drop(4)
    |> filter(int.is_even)
    |> gen(5)
    == [4, 6, 8, 10, 12]
  assert new()
    |> filter(int.is_even)
    |> drop(4)
    |> gen(5)
    == [8, 10, 12, 14, 16]
}

// Testing the next function for the generator type
pub fn next_test() {
  let #(x, g) = new() |> next
  assert x == 0
  assert g |> gen(3) == [1, 2, 3]
}

// Testing the zip function for 2 gens
pub fn zip_test() {
  let g1 = new() |> map(fn(x) { x + 2 })
  let g2 = new() |> filter(int.is_even)
  assert zip(g1, g2)
    |> gen(3)
    == [#(2, 0), #(4, 2), #(6, 4)]
}

// Testing the list_zip function
pub fn list_zip_test() {
  assert ["a", "b", "c"] |> list_zip(new()) == [#("a", 0), #("b", 1), #("c", 2)]
}

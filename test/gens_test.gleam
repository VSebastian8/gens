import gens.{drop, filter, list_zip, map, new, take, zip}
import gleam/int
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

// Basic test for the default takeerator and the take function
pub fn take_test() {
  assert take(new(), 0) == []
  assert take(new(), 1) == [0]
  assert new() |> take(5) == [0, 1, 2, 3, 4]
}

// Testing the map function for the takeerator type
pub fn map_test() {
  assert new()
    |> map(fn(x) { x + 3 })
    |> map(int.to_string)
    |> take(5)
    == ["3", "4", "5", "6", "7"]
}

// Testing the filter function for the takeerator type
pub fn filter_test() {
  assert new()
    |> filter(fn(x) { x % 2 == 0 })
    |> filter(fn(x) { x != 4 })
    |> take(5)
    == [0, 2, 6, 8, 10]
}

// Testing the drop function for the takeerator type
pub fn drop_test() {
  assert new()
    |> drop(0)
    |> take(1)
    == [0]
  assert new()
    |> drop(1)
    |> take(1)
    == [1]
  assert new()
    |> drop(4)
    |> filter(int.is_even)
    |> take(5)
    == [4, 6, 8, 10, 12]
  assert new()
    |> filter(int.is_even)
    |> drop(4)
    |> take(5)
    == [8, 10, 12, 14, 16]
}

// Testing the zip function for 2 takes
pub fn zip_test() {
  let g1 = new() |> map(fn(x) { x + 2 })
  let g2 = new() |> filter(int.is_even)
  assert zip(g1, g2)
    |> take(3)
    == [#(2, 0), #(4, 2), #(6, 4)]
}

// Testing the list_zip function
pub fn list_zip_test() {
  assert ["a", "b", "c"] |> list_zip(new()) == [#("a", 0), #("b", 1), #("c", 2)]
}

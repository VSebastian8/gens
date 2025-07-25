import gens/lazy.{alternative, drop, filter, list_zip, map, new, take, zip}
import gleam/int
import gleeunit
import gleeunit/should

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn take_test() {
  assert take(new(), 0) == []
  assert take(new(), 1) == [0]
  assert new() |> take(5) == [0, 1, 2, 3, 4]
}

pub fn map_test() {
  assert new()
    |> map(fn(x) { x + 3 })
    |> map(int.to_string)
    |> take(5)
    == ["3", "4", "5", "6", "7"]
}

pub fn filter_test() {
  assert new()
    |> filter(fn(x) { x % 2 == 0 })
    |> filter(fn(x) { x != 4 })
    |> take(5)
    == [0, 2, 6, 8, 10]
}

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

pub fn zip_test() {
  let g1 = new() |> map(fn(x) { x + 2 })
  let g2 = new() |> filter(int.is_even)
  assert zip(g1, g2)
    |> take(3)
    == [#(2, 0), #(4, 2), #(6, 4)]
}

pub fn list_zip_test() {
  assert ["a", "b", "c"] |> list_zip(new()) == [#("a", 0), #("b", 1), #("c", 2)]
}

pub fn lazy_alternative_test() {
  let odd_pears =
    new()
    |> filter(int.is_odd)
    |> map(fn(x) { int.to_string(x) <> " pears" })
  let triple_kiwis =
    new()
    |> drop(3)
    |> filter(fn(x) { x % 3 == 0 })
    |> map(fn(x) { int.to_string(x) <> " kiwis" })
  // Combining the two lists
  let fruits = alternative().or(odd_pears, triple_kiwis)
  take(fruits, 8)
  |> should.equal([
    "3 pears", "5 pears", "6 kiwis", "7 pears", "9 pears", "11 pears",
    "12 kiwis", "13 pears",
  ])
}

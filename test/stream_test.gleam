import gens/stream.{type Stream, Stream, drop, filter, list_zip, map, take, zip}
import gleam/int
import gleeunit/should

pub fn ones() -> Stream(Int) {
  Stream(head: fn() { 1 }, tail: ones)
}

pub fn take_test() {
  ones()
  |> take(5)
  |> should.equal([1, 1, 1, 1, 1])
}

pub fn alt(positive: Bool) -> Stream(Int) {
  Stream(
    head: fn() {
      case positive {
        True -> 1
        False -> -1
      }
    },
    tail: fn() { alt(!positive) },
  )
}

pub fn map_test() {
  alt(True)
  |> map(fn(x) { x * 2 })
  |> map(fn(x) { int.to_string(x) <> " oranges" })
  |> take(5)
  |> should.equal([
    "2 oranges", "-2 oranges", "2 oranges", "-2 oranges", "2 oranges",
  ])
}

pub fn naturals() -> Stream(Int) {
  Stream(head: fn() { 0 }, tail: fn() { map(naturals(), fn(x) { x + 1 }) })
}

pub fn filter_test() {
  filter(naturals(), fn(x) { x % 3 == 0 })
  |> take(5)
  |> should.equal([0, 3, 6, 9, 12])
}

pub fn powers() -> Stream(Int) {
  Stream(head: fn() { 1 }, tail: fn() { map(powers(), fn(x) { x * 2 }) })
}

pub fn drop_test() {
  powers()
  |> drop(3)
  |> take(5)
  |> should.equal([8, 16, 32, 64, 128])
}

pub fn zip_test() {
  zip(naturals(), drop(naturals(), 5))
  |> take(3)
  |> should.equal([#(0, 5), #(1, 6), #(2, 7)])

  list_zip(["a", "b", "c"], naturals())
  |> should.equal([#("a", 0), #("b", 1), #("c", 2)])
}

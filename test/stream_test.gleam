import gens/stream.{type Stream, Stream, map, take}
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

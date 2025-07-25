import gens/stream.{
  type Stream, Stream, drop, filter, fold, list_zip, map, merge, scan, take,
  while, zip,
}
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

pub fn while_test() {
  naturals()
  |> while(fn(x) { x < 5 })
  |> should.equal([0, 1, 2, 3, 4])
}

pub fn dummy() -> Stream(Nil) {
  Stream(head: fn() { Nil }, tail: dummy)
}

pub fn scan_test() {
  let evens: Stream(Int) = scan(dummy(), 0, fn(_, acc) { acc + 2 })
  evens
  |> take(5)
  |> should.equal([0, 2, 4, 6, 8])
}

pub fn merge_test() {
  merge(naturals(), naturals() |> map(fn(x) { x * 2 }), int.compare)
  |> take(8)
  |> should.equal([0, 0, 1, 2, 2, 3, 4, 4])
}

pub fn fold_test() {
  // If at least one element is True, then the fold ends
  // If all elements in the Stream are False, the fold runs infinitely
  let stream_or =
    fold(naturals() |> map(fn(x) { x == 10 }), fn(x, next) { x || next() })
    |> should.equal(True)
}

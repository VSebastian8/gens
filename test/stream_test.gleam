import gens/lazy
import gens/stream.{
  type Stream, Stream, distinct, drop, filter, flatten, fold, from_lazy_list,
  list_zip, map, merge, scan, take, to_lazy_list, while, zip,
}
import gleam/int
import gleam/list

pub fn ones() -> Stream(Int) {
  Stream(head: fn() { 1 }, tail: ones)
}

pub fn take_test() {
  assert ones() |> take(5) == [1, 1, 1, 1, 1]
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
  assert alt(True)
    |> map(fn(x) { x * 2 })
    |> map(fn(x) { int.to_string(x) <> " oranges" })
    |> take(5)
    == ["2 oranges", "-2 oranges", "2 oranges", "-2 oranges", "2 oranges"]
}

pub fn naturals() -> Stream(Int) {
  Stream(head: fn() { 0 }, tail: fn() { map(naturals(), fn(x) { x + 1 }) })
}

pub fn filter_test() {
  assert filter(naturals(), fn(x) { x % 3 == 0 })
    |> take(5)
    == [0, 3, 6, 9, 12]
}

pub fn powers() -> Stream(Int) {
  Stream(head: fn() { 1 }, tail: fn() { map(powers(), fn(x) { x * 2 }) })
}

pub fn drop_test() {
  assert powers()
    |> drop(3)
    |> take(5)
    == [8, 16, 32, 64, 128]
}

pub fn zip_test() {
  assert zip(naturals(), drop(naturals(), 5))
    |> take(3)
    == [#(0, 5), #(1, 6), #(2, 7)]

  assert list_zip(["a", "b", "c"], naturals())
    == [#("a", 0), #("b", 1), #("c", 2)]
}

pub fn while_test() {
  assert naturals()
    |> while(fn(x) { x < 5 })
    == [0, 1, 2, 3, 4]
}

pub fn dummy() -> Stream(Nil) {
  Stream(head: fn() { Nil }, tail: dummy)
}

pub fn scan_test() {
  let evens: Stream(Int) = scan(dummy(), 0, fn(_, acc) { acc + 2 })
  assert evens |> take(5) == [0, 2, 4, 6, 8]
}

pub fn merge_test() {
  assert merge(naturals(), naturals() |> map(fn(x) { x * 2 }), int.compare)
    |> take(8)
    == [0, 0, 1, 2, 2, 3, 4, 4]
}

pub fn fold_test() {
  let stream_or = fn(s: Stream(Bool)) -> Bool {
    fold(s, fn(x, next) { x || next() })
  }
  // If at least one element is True, then the fold ends
  // If all elements in the Stream are False, the fold runs infinitely
  assert stream_or(naturals() |> map(fn(x) { x == 10 })) == True
}

pub fn flatten_test() {
  let repeat_stream = naturals() |> map(fn(x) { list.repeat(x, x) })
  assert repeat_stream
    |> take(5)
    == [[], [1], [2, 2], [3, 3, 3], [4, 4, 4, 4]]
  assert repeat_stream
    |> flatten()
    |> take(10)
    == [1, 2, 2, 3, 3, 3, 4, 4, 4, 4]
}

pub fn lazy_test() {
  let lazy_odds =
    lazy.new()
    |> lazy.filter(int.is_odd)
    |> lazy.map(int.to_string)
  let stream_odds = from_lazy_list(lazy_odds)
  assert stream_odds
    |> take(5)
    == ["1", "3", "5", "7", "9"]

  let stream_evens =
    naturals()
    |> filter(int.is_even)
    |> map(int.to_string)
  let lazy_evens = to_lazy_list(stream_evens)
  assert lazy_evens |> lazy.take(5) == ["0", "2", "4", "6", "8"]
}

pub fn distinct_test() {
  assert map(naturals(), fn(x) { x / 3 })
    |> take(10)
    == [0, 0, 0, 1, 1, 1, 2, 2, 2, 3]
  assert map(naturals(), fn(x) { x / 3 })
    |> distinct()
    |> take(5)
    == [0, 1, 2, 3, 4]
  assert naturals()
    |> map(fn(x) { [x, x + 3] })
    |> flatten()
    |> distinct()
    |> take(10)
    == [0, 3, 1, 4, 2, 5, 6, 7, 8, 9]
}

////================== Stream ==================

import gleam/list
import gleam/order.{type Order, Gt}

pub type Stream(a) {
  Stream(head: fn() -> a, tail: fn() -> Stream(a))
}

/// `Tail recursive` function for **take**
fn take_acc(stream: Stream(a), n: Int, acc: List(a)) -> List(a) {
  case n > 0 {
    False -> list.reverse(acc)
    True -> take_acc(stream.tail(), n - 1, [stream.head(), ..acc])
  }
}

/// **Takes** a `finite` number of elements from the Stream
/// ```gleam
/// pub fn ones() -> Stream(Int) {
///   Stream(head: fn() { 1 }, tail: ones)
/// }
/// ```
/// ```gleam
/// ones()
/// |> take(5)
/// // -> [1, 1, 1, 1, 1]
/// ```
pub fn take(stream: Stream(a), n: Int) -> List(a) {
  take_acc(stream, n, [])
}

/// **Maps** each element of the Stream
/// ```gleam
/// pub fn alt(positive: Bool) -> Stream(Int) {
///   Stream(
///     head: fn() {
///       case positive {
///         True -> 1
///         False -> -1
///       }
///     },
///     tail: fn() { alt(!positive) },
///   )
/// }
/// ```
/// ```gleam
/// alt(True)
/// |> map(fn(x) { x * 2 })
/// |> map(fn(x) { int.to_string(x) <> " oranges" })
/// |> take(5)
/// // -> ["2 oranges", "-2 oranges", "2 oranges", "-2 oranges", "2 oranges"]
/// ```
pub fn map(stream: Stream(a), f: fn(a) -> b) -> Stream(b) {
  Stream(head: fn() { f(stream.head()) }, tail: fn() { map(stream.tail(), f) })
}

/// Lazy function for getting the filtered stream's head
fn loop_head(stream: Stream(a), pred: fn(a) -> Bool) -> a {
  let current = stream.head()
  case pred(current) {
    True -> current
    False -> loop_head(stream.tail(), pred)
  }
}

/// Lazy function for getting the filtered stream's tail
fn loop_tail(stream: Stream(a), pred: fn(a) -> Bool) -> Stream(a) {
  let current = stream.head()
  case pred(current) {
    True -> filter(stream.tail(), pred)
    False -> loop_tail(stream.tail(), pred)
  }
}

/// **Filters** elements from the Stream
/// ```gleam
/// pub fn naturals() -> Stream(Int) {
///   Stream(head: fn() { 0 }, tail: fn() { map(naturals(), fn(x) { x + 1 }) })
/// }
/// ```
/// ```gleam
/// filter(naturals(), fn(x) { x % 3 == 0 })
/// |> take(5)
/// // -> [0, 3, 6, 9, 12]
/// ```
pub fn filter(stream: Stream(a), pred: fn(a) -> Bool) -> Stream(a) {
  Stream(head: fn() { loop_head(stream, pred) }, tail: fn() {
    loop_tail(stream, pred)
  })
}

/// **Drops** the first n elements from the Stream
/// ```gleam
/// pub fn powers() -> Stream(Int) {
///   Stream(head: fn() { 1 }, tail: fn() { map(powers(), fn(x) { x * 2 }) })
/// }
/// ```
/// ```gleam
/// powers() // 1, 2, 4, 8, 16..
/// |> drop(3)
/// |> take(5)
/// // -> [8, 16, 32, 64, 128]
/// ```
pub fn drop(stream: Stream(a), n: Int) -> Stream(a) {
  case n > 0 {
    True -> drop(stream.tail(), n - 1)
    False -> stream
  }
}

/// **Zips** two Streams togheter
/// ```gleam
/// zip(naturals(), drop(naturals(), 5))
/// |> take(3)
/// |> [#(0, 5), #(1, 6), #(2, 7)]
/// ``` 
pub fn zip(a_stream: Stream(a), b_stream: Stream(b)) -> Stream(#(a, b)) {
  Stream(head: fn() { #(a_stream.head(), b_stream.head()) }, tail: fn() {
    zip(a_stream.tail(), b_stream.tail())
  })
}

/// **Zips** a list with a Stream
/// ```gleam
/// list_zip(["a", "b", "c"], naturals())
/// // -> [#("a", 0), #("b", 1), #("c", 2)]
/// ```
pub fn list_zip(list: List(a), stream: Stream(b)) -> List(#(a, b)) {
  case list {
    [] -> []
    [x, ..xs] -> [#(x, stream.head()), ..list_zip(xs, stream.tail())]
  }
}

/// **Takes** elements from the Stream until the condition is false
/// ```gleam
///   naturals()
/// |> while(fn(x) { x < 5 })
/// // -> [0, 1, 2, 3, 4]
/// ```
pub fn while(stream: Stream(a), condition: fn(a) -> Bool) -> List(a) {
  case condition(stream.head()) {
    False -> []
    True -> [stream.head(), ..while(stream.tail(), condition)]
  }
}

/// **Scans** the Stream and reconstructs it using an accumulator
/// ```gleam
/// pub fn dummy() -> Stream(Nil) {
///   Stream(head: fn() { Nil }, tail: dummy)
/// }
/// ```
/// ```gleam
/// let evens: Stream(Int) = scan(dummy(), 0, fn(_, acc) { acc + 2 })
/// evens
/// |> take(5)
/// // -> [0, 2, 4, 6, 8]
/// ```
pub fn scan(stream: Stream(a), acc: b, f: fn(a, b) -> b) -> Stream(b) {
  Stream(head: fn() { acc }, tail: fn() {
    scan(stream.tail(), f(stream.head(), acc), f)
  })
}

/// **Merges** two sorted Streams
/// ```gleam
/// merge(naturals(), naturals() |> map(fn(x) { x * 2 }), int.compare)
/// |> take(8)
/// // -> [0, 0, 1, 2, 2, 3, 4, 4]
/// ```
pub fn merge(
  stream1: Stream(a),
  stream2: Stream(a),
  compare: fn(a, a) -> Order,
) -> Stream(a) {
  Stream(
    head: fn() {
      case compare(stream1.head(), stream2.head()) {
        Gt -> stream2.head()
        _ -> stream1.head()
      }
    },
    tail: fn() {
      case compare(stream1.head(), stream2.head()) {
        Gt -> merge(stream1, stream2.tail(), compare)
        _ -> merge(stream1.tail(), stream2, compare)
      }
    },
  )
}

/// **Folds** the Stream into a single value using an accumulator
/// ```gleam
/// // If at least one element is True, then the fold ends
/// // If all elements in the Stream are False, the fold runs infinitely
/// let stream_or =
///   fold(naturals() |> map(fn(x) { x == 10 }), fn(x, next) { x || next() })
///   // -> True
/// ```
pub fn fold(stream: Stream(a), f: fn(a, fn() -> b) -> b) -> b {
  f(stream.head(), fn() { fold(stream.tail(), f) })
}

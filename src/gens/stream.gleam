////================== Stream ==================

import gleam/list

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

/// **Takes** a `finite` number of elements from a Stream
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

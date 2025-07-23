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

////================== Lazy List ==================

import cat/alternative.{type Alternative, Alternative}
import gleam/int
import gleam/list

pub opaque type LazyList(a) {
  LazyList(index: Int, map: fn(Int) -> a, filter: fn(Int) -> Bool)
}

/// Default LazyList for the list of `natural numbers` [0..]
/// ```gleam
/// new() |> take(5)
/// // -> [0, 1, 2, 3, 4]
/// ```
pub fn new() -> LazyList(Int) {
  LazyList(0, fn(x) { x }, fn(_) { True })
}

/// `Tail recursive` function for **take**
fn take_acc(
  index: Int,
  step: Int,
  total: Int,
  fmap: fn(Int) -> a,
  filt: fn(Int) -> Bool,
  acc: List(a),
) {
  case step < total {
    False -> acc |> list.reverse
    True ->
      case filt(index) {
        False -> take_acc(index + 1, step, total, fmap, filt, acc)
        True ->
          case step >= 0 {
            False -> take_acc(index + 1, step + 1, total, fmap, filt, acc)
            True ->
              take_acc(index + 1, step + 1, total, fmap, filt, [
                fmap(index),
                ..acc
              ])
          }
      }
  }
}

/// **Takes** a `finite` number of elements from a LazyList
/// ```gleam
/// take(new(), 5)
/// // -> [0, 1, 2, 3, 4]
/// ```
pub fn take(ga: LazyList(a), n: Int) -> List(a) {
  case ga {
    LazyList(index, amap, afilt) -> take_acc(index, 0, n, amap, afilt, [])
  }
}

/// **Maps** each element of the gerated list
/// ```gleam
/// new()
/// |> map(fn(x) { x + 3 })
/// |> map(int.to_string)
/// |> take(5)
/// // -> ["3", "4", "5", "6", "7"]
/// ```
pub fn map(ga: LazyList(a), f: fn(a) -> b) -> LazyList(b) {
  case ga {
    LazyList(index, amap, afilt) -> LazyList(index, fn(n) { f(amap(n)) }, afilt)
  }
}

/// **Filters** elements from the generated list
/// ```gleam
/// new()
/// |> filter(fn(x) { x % 2 == 0 })
/// |> filter(fn(x) { x != 4 })
/// |> take(5)
/// // -> [0, 2, 6, 8, 10]
/// ```
pub fn filter(ga: LazyList(a), f: fn(a) -> Bool) -> LazyList(a) {
  case ga {
    LazyList(index, amap, afilt) ->
      LazyList(index, amap, fn(n) { afilt(n) && f(amap(n)) })
  }
}

// `Tail recursive` function used for skipping generated elements
fn advance(index: Int, steps: Int, filt: fn(Int) -> Bool) -> Int {
  case steps >= 0 {
    False -> index - 1
    True ->
      case filt(index) {
        False -> advance(index + 1, steps, filt)
        True -> advance(index + 1, steps - 1, filt)
      }
  }
}

/// **Drops** the first n elements of a LazyList
/// ```gleam
/// new()                   // [0, 1, 2, 3, 4..]
/// |> drop(4)              // [4, 5, 6, 7..]
/// |> filter(int.is_even)  // [4, 6, 8..]
/// |> take(5)
/// // -> [4, 6, 8, 10, 12]
/// ```
/// ```gleam
/// new()                   // [0, 1, 2, 3, 4..]
/// |> filter(int.is_even)  // [0, 2, 4, 6, 8..]
/// |> drop(4)              // [8, 10, 12..]
/// |> take(5)
/// // -> [8, 10, 12, 14, 16]
/// ```
pub fn drop(ga: LazyList(a), steps: Int) -> LazyList(a) {
  case steps >= 0 {
    False -> ga
    True ->
      case ga {
        LazyList(index, amap, afilt) ->
          LazyList(advance(index, steps, afilt), amap, afilt)
      }
  }
}

/// **Zips** two LazyLists into one
/// - The resulting index is the maximum of the two takes 
/// - The filters get combined
/// - For separate indexes, do `list.zip(take(g1,  n), take(g2, n))`
/// ```gleam
/// let g1 = new() |> map(fn(x) { x + 2 })
/// let g2 = new() |> filter(int.is_even)
/// zip(g1, g2)
/// |> take(3)
/// // -> [#(2, 0), #(4, 2), #(6, 4)]
/// ```
pub fn zip(ga: LazyList(a), gb: LazyList(b)) -> LazyList(#(a, b)) {
  let LazyList(aindex, amap, afilt) = ga
  let LazyList(bindex, bmap, bfilt) = gb
  LazyList(int.max(aindex, bindex), fn(n) { #(amap(n), bmap(n)) }, fn(n) {
    afilt(n) && bfilt(n)
  })
}

/// **Zips** a list with an infinite list
/// ```gleam
/// ["a", "b", "c"] 
/// |> list_zip(new())
/// // -> [#("a", 0), #("b", 1), #("c", 2)]
/// ```
pub fn list_zip(la: List(a), gb: LazyList(b)) -> List(#(a, b)) {
  list.zip(la, take(gb, list.length(la)))
}

/// Phantom type for LazyList cat instances
pub type LazyListF

/// `Alternative` instance for `LazyList`
/// ```gleam
/// let odd_pears =
///   new()
///   |> filter(int.is_odd)
///   |> map(fn(x) { int.to_string(x) <> " pears" })
/// let triple_kiwis =
///   new()
///   |> drop(3)
///   |> filter(fn(x) { x % 3 == 0 })
///   |> map(fn(x) { int.to_string(x) <> " kiwis" })
/// // Combining the two lists
/// let fruits = alternative().or(odd_pears, triple_kiwis)
/// take(fruits, 8)
/// // -> ["3 pears", "5 pears", "6 kiwis", "7 pears", "9 pears", "11 pears", "12 kiwis", "13 pears"]
/// ```
pub fn alternative() -> Alternative(LazyListF, LazyList(a)) {
  Alternative(
    empty: LazyList(index: 0, map: fn(_) { panic }, filter: fn(_) { False }),
    or: fn(l1, l2) {
      LazyList(
        index: int.max(l1.index, l2.index),
        map: fn(n) {
          case l1.filter(n) {
            True -> l1.map(n)
            False -> l2.map(n)
          }
        },
        filter: fn(x) { l1.filter(x) || l2.filter(x) },
      )
    },
  )
}

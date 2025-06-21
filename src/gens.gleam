import gleam/int
import gleam/list

pub opaque type Generator(a) {
  Generator(Int, fn(Int) -> a, fn(Int) -> Bool)
}

/// Default generator for the list of `natural numbers` [0..]
/// ```gleam
/// new() |> gen(5)
/// // -> [0, 1, 2, 3, 4]
/// ```
pub fn new() -> Generator(Int) {
  Generator(0, fn(x) { x }, fn(_) { True })
}

/// `Tail recursive` function for **gen**
fn gen_acc(
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
        False -> gen_acc(index + 1, step, total, fmap, filt, acc)
        True ->
          case step >= 0 {
            False -> gen_acc(index + 1, step + 1, total, fmap, filt, acc)
            True ->
              gen_acc(index + 1, step + 1, total, fmap, filt, [
                fmap(index),
                ..acc
              ])
          }
      }
  }
}

/// **Generates** a `finite list` from a generator and a length
/// ```gleam
/// gen(new(), 5)
/// // -> [0, 1, 2, 3, 4]
/// ```
pub fn gen(ga: Generator(a), n: Int) -> List(a) {
  case ga {
    Generator(index, amap, afilt) -> gen_acc(index, 0, n, amap, afilt, [])
  }
}

/// **Maps** each element of the generated list
/// ```gleam
/// new()
/// |> map(fn(x) { x + 3 })
/// |> map(int.to_string)
/// |> gen(5)
/// // -> ["3", "4", "5", "6", "7"]
/// ```
pub fn map(ga: Generator(a), f: fn(a) -> b) -> Generator(b) {
  case ga {
    Generator(index, amap, afilt) ->
      Generator(index, fn(n) { f(amap(n)) }, afilt)
  }
}

/// **Filters** elements from the generated list
/// ```gleam
/// new()
/// |> filter(fn(x) { x % 2 == 0 })
/// |> filter(fn(x) { x != 4 })
/// |> gen(5)
/// // -> [0, 2, 6, 8, 10]
/// ```
pub fn filter(ga: Generator(a), f: fn(a) -> Bool) -> Generator(a) {
  case ga {
    Generator(index, amap, afilt) ->
      Generator(index, amap, fn(n) { afilt(n) && f(amap(n)) })
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

/// **Drops** the first n generated elements
/// ```gleam
/// new()                   // [0, 1, 2, 3, 4..]
/// |> drop(4)              // [4, 5, 6, 7..]
/// |> filter(int.is_even)  // [4, 6, 8..]
/// |> gen(5)
/// // -> [4, 6, 8, 10, 12]
/// new()                   // [0, 1, 2, 3, 4..]
/// |> filter(int.is_even)  // [0, 2, 4, 6, 8..]
/// |> drop(4)              // [8, 10, 12..]
/// |> gen(5)
/// // -> [8, 10, 12, 14, 16]
/// ```
pub fn drop(ga: Generator(a), steps: Int) -> Generator(a) {
  case steps >= 0 {
    False -> ga
    True ->
      case ga {
        Generator(index, amap, afilt) ->
          Generator(advance(index, steps, afilt), amap, afilt)
      }
  }
}

// `Tail recursive` function for calculating the next index and its value
fn next_index(
  index: Int,
  fmap: fn(Int) -> a,
  filt: fn(Int) -> Bool,
) -> #(a, Int) {
  case filt(index) {
    False -> next_index(index + 1, fmap, filt)
    True -> #(fmap(index), index)
  }
}

/// **Yields** one element and advances the generator
/// ```gleam
/// let #(x, g) = new() |> next
/// // -> #(0, Generator(Int))
/// g |> gen(3)
/// // -> [1, 2, 3]
/// ```
pub fn next(ga: Generator(a)) -> #(a, Generator(a)) {
  case ga {
    Generator(index, amap, afilt) -> {
      let #(element, new_index) = next_index(index, amap, afilt)
      #(element, Generator(new_index + 1, amap, afilt))
    }
  }
}

/// **Combines** two generators into one \
/// - The resulting index is the maximum of the two gens 
/// - The filters get combined
/// - For separate indexes, do `list.zip(gen(g1,  n), gen(g2, n))`
/// ```gleam
/// let g1 = new() |> map(fn(x) { x + 2 })
/// let g2 = new() |> filter(int.is_even)
/// zip(g1, g2)
/// |> gen(3)
/// // -> [#(2, 0), #(4, 2), #(6, 4)]
/// ```
pub fn zip(ga: Generator(a), gb: Generator(b)) -> Generator(#(a, b)) {
  let Generator(aindex, amap, afilt) = ga
  let Generator(bindex, bmap, bfilt) = gb
  Generator(int.max(aindex, bindex), fn(n) { #(amap(n), bmap(n)) }, fn(n) {
    afilt(n) && bfilt(n)
  })
}

/// **Zips** a list with an infinite list
/// ```gleam
/// ["a", "b", "c"] 
/// |> list_zip(new())
/// // -> [#("a", 0), #("b", 1), #("c", 2)]
/// ```
pub fn list_zip(la: List(a), gb: Generator(b)) -> List(#(a, b)) {
  list.zip(la, gen(gb, list.length(la)))
}

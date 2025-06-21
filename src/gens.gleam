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
  len: Int,
  total: Int,
  fmap: fn(Int) -> a,
  filt: fn(Int) -> Bool,
  acc: List(a),
) {
  case len < total {
    False -> acc |> list.reverse
    True ->
      case filt(index) {
        False -> gen_acc(index + 1, len, total, fmap, filt, acc)
        True ->
          gen_acc(index + 1, len + 1, total, fmap, filt, [fmap(index), ..acc])
      }
  }
}

/// Generates a `finite list` from a generator and a length
/// ```gleam
/// gen(new(), 5)
/// // -> [0, 1, 2, 3, 4]
/// ```
pub fn gen(ga: Generator(a), n: Int) -> List(a) {
  case ga {
    Generator(step, amap, afilt) -> gen_acc(step, 0, n, amap, afilt, [])
  }
}

/// Maps each element of the generated list
/// ```gleam
/// new()
/// |> map(fn(x) { x + 3 })
/// |> map(int.to_string)
/// |> gen(5)
/// // -> ["3", "4", "5", "6", "7"]
/// ```
pub fn map(ga: Generator(a), f: fn(a) -> b) -> Generator(b) {
  case ga {
    Generator(step, amap, afilt) -> Generator(step, fn(n) { f(amap(n)) }, afilt)
  }
}

/// Filters elements from the generated list
/// ```gleam
/// new()
/// |> filter(fn(x) { x % 2 == 0 })
/// |> filter(fn(x) { x != 4 })
/// |> gen(5)
/// // -> [0, 2, 6, 8, 10]
/// ```
pub fn filter(ga: Generator(a), f: fn(a) -> Bool) -> Generator(a) {
  case ga {
    Generator(step, amap, afilt) ->
      Generator(step, amap, fn(n) { afilt(n) && f(amap(n)) })
  }
}

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
  let Generator(step, amap, afilt) = ga
  gen_acc(step, 0, n, amap, afilt, [])
}

pub fn main() -> Nil {
  echo new() |> gen(5)
  Nil
}

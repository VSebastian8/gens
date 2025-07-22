import cat/alternative.{type Alternative, Alternative}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleam/pair
import gleam/result

pub type Generator(a, s) {
  Generator(state: s, next: fn(s) -> Option(#(a, s)))
}

/// Returns the next element of a generator and the updated gen
/// ```gleam
/// let counter =
///   Generator(state: 0, next: fn(c) { Some(#(c, c + 1)) })
/// case get(counter).0 {
///   None -> echo "no more numbers"
///   Some(x) -> echo x // -> 0
/// }
/// ```
pub fn get(g: Generator(a, s)) -> #(Option(a), Generator(a, s)) {
  case g.next(g.state) {
    None -> #(None, g)
    Some(#(x, s)) -> #(Some(x), Generator(state: s, next: g.next))
  }
}

/// Tail recursive function for gen 
fn gen_acc(
  g: Generator(a, s),
  n: Int,
  ls: List(a),
) -> #(List(a), Generator(a, s)) {
  case n > 0 {
    False -> #(list.reverse(ls), g)
    True ->
      case get(g) {
        #(None, _) -> #(list.reverse(ls), g)
        #(Some(x), g2) -> gen_acc(g2, n - 1, [x, ..ls])
      }
  }
}

/// Generates at most n elements and returns the updated gen
/// ```gleam
/// let counter =
///   Generator(state: 0, next: fn(c) { Some(#(c, c + 1)) })
/// let #(nums, _) = gen(counter, 5)
/// echo nums // -> [0, 1, 2, 3, 4]
/// ```
pub fn gen(g: Generator(a, s), n: Int) -> #(List(a), Generator(a, s)) {
  gen_acc(g, n, [])
}

/// Combines two generators into one, advancing them separately
/// ```gleam
/// let two_powers =
///   Generator(state: 1, next: fn(p) { Some(#(p, p * 2)) })
/// let bellow_three =
///   Generator(state: 0, next: fn(n) { Some(#(n < 3, n + 1)) })
///
/// let z = combine(two_powers, bellow_three)
/// let #(res, _) = gen(z, 5)
/// echo res
/// // -> [#(1, True), #(2, True), #(4, True), #(8, False), #(16, False)]
/// ```
pub fn combine(
  g1: Generator(a, s1),
  g2: Generator(b, s2),
) -> Generator(#(a, b), #(s1, s2)) {
  Generator(state: #(g1.state, g2.state), next: fn(state) {
    let #(state1, state2) = state
    let res1 = g1.next(state1)
    let res2 = g2.next(state2)
    case res1, res2 {
      Some(#(x, state3)), Some(#(y, state4)) ->
        Some(#(#(x, y), #(state3, state4)))
      _, _ -> None
    }
  })
}

/// Generates the lists elements
/// ```gleam
/// let gen_fruit = from_list(["apple", "banana", "orange"])
/// let #(fruit1, gen_fruit2) = get(gen_fruit)
/// echo fruit1
/// // -> Some("apple")
/// ```
/// ```gleam
/// let #(fruit2, gen_fruit3) = get(gen_fruit2)
/// echo fruit2
/// // -> Some("banana")
/// ```
/// ```gleam
/// let #(fruit3, gen_fruit4) = get(gen_fruit3)
/// echo fruit3
/// // -> Some("orange")
/// ```
/// ```gleam
/// let #(fruit4, _) = get(gen_fruit4)
/// echo fruit4
/// // -> None
/// ```
pub fn from_list(l: List(a)) -> Generator(a, List(a)) {
  Generator(state: l, next: fn(ls) {
    case ls {
      [] -> None
      [x, ..rest] -> Some(#(x, rest))
    }
  })
}

/// Generates the lists elements on repeat
/// ```gleam
/// let gen_fruit = list_repeat(["apple", "banana", "orange"])
/// let #(fruits, _) = gen(gen_fruit, 5)
/// echo fruits
/// // -> ["apple", "banana", "orange", "apple", "banana"]
/// ```
pub fn list_repeat(l: List(a)) -> Generator(a, #(List(a), List(a))) {
  Generator(state: #(l, l), next: fn(list_pair) {
    let #(current, original) = list_pair
    case current {
      [] -> None
      [x, ..rest] ->
        case rest {
          [] -> Some(#(x, #(original, original)))
          _ -> Some(#(x, #(rest, original)))
        }
    }
  })
}

/// Generates elements from the lazy list
/// ```gleam
/// let infinite_list = new() |> drop(3) |> map(fn(x) { x * 10 })
/// let ten_gen = from_lazy_list(infinite_list)
/// let #(res, _) = gen(ten_gen, 10)
/// echo res
/// // -> [30, 40, 50, 60, 70, 80, 90, 100, 110, 120]
/// ```
pub fn from_lazy_list(l: LazyList(a)) -> Generator(a, LazyList(a)) {
  Generator(state: l, next: fn(ls) {
    case take(ls, 1) {
      [] -> None
      [x, ..] -> Some(#(x, ls |> drop(1)))
    }
  })
}

/// Generates a list of all the elements. \
/// If the generator does not have a reachable end condition, then this function does not end!!!
/// ```gleam
/// let gen_ten =
///   Generator(5, fn(x) {
///     case x < 10 {
///       True -> Some(#(x, x + 2))
///       False -> None
///     }
///   })
/// echo while(gen_ten)
/// // -> [5, 7, 9]
/// ```
/// This function is the in verse of `from_list`
/// ```gleam
/// let gen_li = from_list(["A", "B", "C"])
/// echo while(gen_li)
/// // -> ["A", "B", "C"]
/// ```
pub fn while(g: Generator(a, s)) -> List(a) {
  case get(g) {
    #(None, _) -> []
    #(Some(x), g2) -> [x, ..while(g2)]
  }
}

/// Generates a lazy list from a generator with no end condition. \
/// Since each element in the lazy list needs to be generated separately, this function can be very slow!!! (O(n^2))
/// ```gleam
/// let gen_nat = Generator(1, fn(c) { Some(#(c, c + 1)) })
/// let lazy_nat = forever(gen_nat)
/// echo take(lazy_nat, 5)
/// // -> [1, 2, 3, 4, 5]
/// ```
/// This function is the inverse of `from_lazy_list`
/// ```gleam
/// let lazy_odds =
///   new()
///   |> filter(int.is_odd)
///   |> map(int.to_string)
/// let gen_odds = from_lazy_list(lazy_odds)
/// let lazy_odds_2 = forever(gen_odds)
/// 
/// echo take(lazy_odds, 5)
/// // -> ["1", "3", "5", "7", "9"]
/// echo gen(gen_odds, 5) |> pair.first
/// // -> ["1", "3", "5", "7", "9"]
/// echo take(lazy_odds_2, 5)
/// // -> ["1", "3", "5", "7", "9"]
/// ```
pub fn forever(g: Generator(a, s)) -> LazyList(a) {
  new()
  |> map(fn(n) { gen(g, n) |> pair.first |> list.last })
  |> filter(result.is_ok)
  |> map(fn(res) {
    case res {
      Ok(x) -> x
      Error(_) -> panic
    }
  })
}

/// Creates a generator with no end condition.
/// ```gleam
/// let gen_nat = infinite(1, fn(x) { #(x, x + 1) })
/// echo gen(gen_nat, 5).0
/// // -> [1, 2, 3, 4, 5]
/// ```
pub fn infinite(state: s, next: fn(s) -> #(a, s)) -> Generator(a, s) {
  Generator(state, fn(x) { Some(next(x)) })
}

/// Merges two `sorted` generators into one
/// ```gleam
/// let counter1 = Generator(0, fn(c) { Some(#(c, c + 1)) })
/// let counter2 = Generator(0, fn(c) { Some(#(c, c + 2)) })
/// let merged = merge(counter1, counter2, int.compare)
/// merged 
/// |> gen(8) 
/// |> echo
/// // -> #([0, 0, 1, 2, 2, 3, 4, 4], Generator(#(5, 6), fn() { ... }))
/// ```
pub fn merge(
  g1: Generator(a, s1),
  g2: Generator(a, s2),
  comp: fn(a, a) -> Order,
) -> Generator(a, #(s1, s2)) {
  Generator(state: #(g1.state, g2.state), next: fn(s) {
    let #(state1, state2) = s
    case g1.next(state1), g2.next(state2) {
      Some(#(x1, st1)), Some(#(x2, st2)) ->
        case comp(x1, x2) {
          order.Gt -> Some(#(x2, #(state1, st2)))
          _ -> Some(#(x1, #(st1, state2)))
        }
      Some(#(x1, st1)), None -> Some(#(x1, #(st1, state2)))
      None, Some(#(x2, st2)) -> Some(#(x2, #(state1, st2)))
      None, None -> None
    }
  })
}

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
/// let fruits = lazy_list_alternative().or(odd_pears, triple_kiwis)
/// take(fruits, 8)
/// // -> ["3 pears", "5 pears", "6 kiwis", "7 pears", "9 pears", "11 pears", "12 kiwis", "13 pears"]
/// ```
pub fn lazy_list_alternative() -> Alternative(LazyListF, LazyList(a)) {
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

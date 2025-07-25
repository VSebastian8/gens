////================== Generator ==================

import cat/monad.{type Monad, Monad}
import gens/lazy.{type LazyList}
import gens/stream.{type Stream, Stream}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleam/pair

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
pub fn list_repeat(l: List(a)) -> Generator(a, List(a)) {
  Generator(state: l, next: fn(ls) {
    case ls {
      [] -> None
      [x, ..rest] ->
        case rest {
          [] -> Some(#(x, l))
          _ -> Some(#(x, rest))
        }
    }
  })
}

/// Conversion from **LazyList** to **Generator** 
/// ```gleam
/// let infinite_list = lazy.new() |> lazy.drop(3) |> lazy.map(fn(x) { x * 10 })
/// let ten_gen = from_lazy_list(infinite_list)
/// let #(res, _) = gen(ten_gen, 10)
/// echo res
/// // -> [30, 40, 50, 60, 70, 80, 90, 100, 110, 120]
/// ```
pub fn from_lazy_list(l: LazyList(a)) -> Generator(a, LazyList(a)) {
  Generator(state: l, next: fn(ls) {
    case lazy.take(ls, 1) {
      [] -> None
      [x, ..] -> Some(#(x, ls |> lazy.drop(1)))
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

/// Conversion from **Generator** to **LazyList** \
/// Since each element in the lazy list needs to be generated separately, this function can be very slow!!! (O(n^2))
/// ```gleam
/// let gen_nat = Generator(1, fn(c) { Some(#(c, c + 1)) })
/// let lazy_nat = forever(gen_nat)
/// echo lazy.take(lazy_nat, 5)
/// // -> [Some(1), Some(2), Some(3), Some(4), Some(5)]
/// ```
/// This function is the inverse of `from_lazy_list`
/// ```gleam
/// let lazy_odds =
///   lazy.new()
///   |> lazy.filter(int.is_odd)
///   |> lazy.map(int.to_string)
/// let gen_odds = from_lazy_list(lazy_odds)
/// let lazy_odds_2 = forever(gen_odds) |> lazy.map(option.lazy_unwrap(_, fn() { panic }))
/// 
/// echo lazy.take(lazy_odds, 5)
/// // -> ["1", "3", "5", "7", "9"]
/// echo gen(gen_odds, 5) |> pair.first
/// // -> ["1", "3", "5", "7", "9"]
/// echo lazy.take(lazy_odds_2, 5)
/// // -> ["1", "3", "5", "7", "9"]
/// ```
pub fn forever(g: Generator(a, s)) -> LazyList(Option(a)) {
  lazy.new()
  |> lazy.map(fn(n) {
    gen(g, n + 1) |> pair.first |> list.drop(n - 1) |> list.last
  })
  |> lazy.map(fn(res) {
    case res {
      Ok(x) -> Some(x)
      Error(_) -> None
    }
  })
}

/// Creates a generator with `no end condition`
/// ```gleam
/// let gen_nat = infinite(1, fn(x) { #(x, x + 1) })
/// echo gen(gen_nat, 5).0
/// // -> [1, 2, 3, 4, 5]
/// ```
pub fn infinite(state: s, next: fn(s) -> #(a, s)) -> Generator(a, s) {
  Generator(state, fn(x) { Some(next(x)) })
}

/// **Merges** two `sorted` generators into one
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

/// Phantom type for Generator cat instances
pub type GeneratorM(s)

// Tail recursive function for Generator's chain
fn chain_tail_rec(
  states: List(s),
  nexts: List(fn(s) -> Option(#(a, s))),
  acc: #(Option(a), List(s)),
) -> #(Option(a), List(s)) {
  case acc {
    #(Some(x), state_list) ->
      case states {
        [st, ..rest_states] ->
          chain_tail_rec(rest_states, [], #(Some(x), [st, ..state_list]))
        [] -> #(Some(x), list.reverse(state_list))
      }
    #(None, state_list) ->
      case states, nexts {
        [st, ..rest_states], [nx, ..rest_nexts] ->
          case nx(st) {
            Some(#(x, new_st)) ->
              chain_tail_rec(
                rest_states,
                [],
                #(Some(x), [new_st, ..state_list]),
              )
            None ->
              chain_tail_rec(
                rest_states,
                rest_nexts,
                #(None, [st, ..state_list]),
              )
          }
        _, _ -> #(None, list.reverse(state_list))
      }
  }
}

/// **Chains** a list of generators
/// ```gleam
/// let gen_three =
///   Generator(1, fn(x) {
///     case x <= 3 {
///       True -> Some(#(x, x + 1))
///       False -> None
///     }
///   })
/// let gen_nat = infinite(1, fn(x) { #(x, x + 1) })
/// // Once the first generator ends, the second one begins
/// let gen_chain = chain([gen_three, gen_nat])
/// gen_chain
/// |> gen(8)
/// |> pair.first
/// // -> [1, 2, 3, 1, 2, 3, 4, 5]
/// ```
pub fn chain(generators: List(Generator(a, s))) -> Generator(a, List(s)) {
  Generator(
    state: generators |> list.map(fn(g) { g.state }),
    next: fn(gen_states) {
      let gen_nexts = generators |> list.map(fn(g) { g.next })
      case chain_tail_rec(gen_states, gen_nexts, #(None, [])) {
        #(None, _) -> None
        #(Some(x), states) -> Some(#(x, states))
      }
    },
  )
}

/// `Monad` instance for `Generator` type
/// ```gleam
/// let plus_one = infinite(1, fn(x) { #(x, x + 1) })
/// let plus_two = infinite(1, fn(x) { #(x, x + 2) })
/// let g = {
///   use x <- monad().bind(plus_one)
///   echo x // -> 1, 4, 7, 10, 13..
///   use y <- monad().map(plus_two)
///   echo y // -> 2, 5, 8, 9, 12..
///   x + y
/// }
/// g |> gen(5) |> pair.first |> echo
/// // -> [3, 9, 15, 21, 27]
/// ```
pub fn monad() -> Monad(GeneratorM(s), a, b, Generator(a, s), Generator(b, s)) {
  Monad(
    return: fn(_) { panic },
    map: fn(g: Generator(a, s), f: fn(a) -> b) {
      Generator(state: g.state, next: fn(state) {
        case g.next(state) {
          None -> None
          Some(#(x, new_state)) -> Some(#(f(x), new_state))
        }
      })
    },
    bind: fn(g: Generator(a, s), f: fn(a) -> Generator(b, s)) {
      Generator(state: g.state, next: fn(state) {
        case g.next(state) {
          None -> None
          Some(#(x, new_state)) -> f(x).next(new_state)
        }
      })
    },
  )
}

/// Conversion from **Stream** to **Generator** \
/// Helper Stream
/// ```gleam
/// pub fn dummy() -> Stream(Nil) {
///   Stream(head: fn() { Nil }, tail: dummy)
/// }
/// ```
/// Fibonacci Stream
/// ```gleam
/// let fibo_s =
///   dummy()
///   |> stream.scan(#(1, 1), fn(_, int_pair) {
///     case int_pair {
///       #(x, y) -> #(y, x + y)
///     }
///   })
///   |> stream.map(fn(int_pair) { int_pair.1 })
/// 
/// fibo_s
/// |> stream.take(5)
/// |> echo
/// // -> [1, 2, 3, 5, 8]
/// ```
/// Fibonacci Generator
/// ```gleam
/// let fibo_g = from_stream(fibo_s)
/// 
/// fibo_g
/// |> gen(5)
/// |> pair.first
/// |> echo
/// // -> [1, 2, 3, 5, 8]
/// ```
pub fn from_stream(stream: Stream(a)) -> Generator(a, Stream(a)) {
  Generator(state: stream, next: fn(s) { Some(#(s.head(), s.tail())) })
}

/// Conversion from **Generator** to **Stream** \
/// Fibonacci Generator
/// ```gleam
/// let fibo_g =
///   Generator(state: #(1, 1), next: fn(int_pair) {
///     case int_pair {
///       #(x, y) -> Some(#(y, #(y, x + y)))
///     }
///   })
///
/// fibo_g
/// |> gen(5)
/// |> pair.first
/// |> echo
/// // -> [1, 2, 3, 5, 8]
/// ```
/// Fibonacci Stream
/// ```gleam
/// let fibo_s = to_stream(fibo_g)
///
/// fibo_s
/// |> stream.map(option.unwrap(_, -1))
/// |> stream.take(5)
/// |> echo
/// // -> [1, 2, 3, 5, 8]
/// ```
pub fn to_stream(generator: Generator(a, s)) -> Stream(Option(a)) {
  Stream(
    head: fn() {
      case get(generator) {
        #(x, _) -> x
      }
    },
    tail: fn() {
      case get(generator) {
        #(_, next_gen) -> to_stream(next_gen)
      }
    },
  )
}

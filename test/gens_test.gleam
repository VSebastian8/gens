import gens.{
  Generator, chain, combine, forever, from_lazy_list, from_list, gen, get,
  infinite, list_repeat, merge, monad, while,
}
import gens/lazy.{drop, filter, map, new, take}
import gleam/int
import gleam/option
import gleam/pair
import gleeunit
import gleeunit/should

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn get_test() {
  let counter = Generator(state: 0, next: fn(c) { option.Some(#(c, c + 1)) })

  case get(counter).0 {
    option.None -> Nil
    option.Some(x) -> should.equal(x, 0)
  }
}

pub fn gen_test() {
  let counter = Generator(state: 0, next: fn(c) { option.Some(#(c, c + 1)) })

  let #(nums, counter2) = gen(counter, 5)
  nums |> should.equal([0, 1, 2, 3, 4])
  counter2.state |> should.equal(5)
}

pub fn combine_test() {
  let two_powers = Generator(state: 1, next: fn(p) { option.Some(#(p, p * 2)) })
  let bellow_three =
    Generator(state: 0, next: fn(n) { option.Some(#(n < 3, n + 1)) })

  let z = combine(two_powers, bellow_three)
  let #(res, _) = gen(z, 5)
  should.equal(res, [
    #(1, True),
    #(2, True),
    #(4, True),
    #(8, False),
    #(16, False),
  ])
}

pub fn from_list_test() {
  let gen_fruit = from_list(["apple", "banana", "orange"])
  let #(fruit1, gen_fruit2) = get(gen_fruit)
  should.equal(fruit1, option.Some("apple"))
  let #(fruit2, gen_fruit3) = get(gen_fruit2)
  should.equal(fruit2, option.Some("banana"))
  let #(fruit3, gen_fruit4) = get(gen_fruit3)
  should.equal(fruit3, option.Some("orange"))
  let #(fruit4, _) = get(gen_fruit4)
  should.equal(fruit4, option.None)
}

pub fn list_repeat_test() {
  let gen_fruit = list_repeat(["apple", "banana", "orange"])
  let #(fruits, _) = gen(gen_fruit, 5)
  should.equal(fruits, ["apple", "banana", "orange", "apple", "banana"])
}

pub fn from_lazy_list_test() {
  let infinite_list = new() |> drop(3) |> map(fn(x) { x * 10 })
  let ten_gen = from_lazy_list(infinite_list)
  let #(res, _) = gen(ten_gen, 10)
  res
  |> should.equal([30, 40, 50, 60, 70, 80, 90, 100, 110, 120])
}

fn fst(t: #(a, b)) {
  let #(x, _) = t
  x
}

pub fn merge_test() {
  let counter1 = Generator(0, fn(c) { option.Some(#(c, c + 1)) })
  let counter2 = Generator(0, fn(c) { option.Some(#(c, c + 2)) })
  let merged = merge(counter1, counter2, int.compare)
  merged |> gen(8) |> fst |> should.equal([0, 0, 1, 2, 2, 3, 4, 4])
}

pub fn while_test() {
  let gen_ten =
    Generator(5, fn(x) {
      case x < 10 {
        True -> option.Some(#(x, x + 2))
        False -> option.None
      }
    })
  while(gen_ten)
  |> should.equal([5, 7, 9])
  // This function is the inverse of `from_list`
  let gen_li = from_list(["A", "B", "C"])
  while(gen_li)
  |> should.equal(["A", "B", "C"])
}

pub fn forever_test() {
  let gen_nat = Generator(1, fn(c) { option.Some(#(c, c + 1)) })
  let lazy_nat = forever(gen_nat)
  take(lazy_nat, 5)
  |> should.equal([1, 2, 3, 4, 5])
  // This function is the inverse of `from_lazy_list`
  let lazy_odds =
    new()
    |> filter(int.is_odd)
    |> map(int.to_string)
  let gen_odds = from_lazy_list(lazy_odds)
  let lazy_odds_2 = forever(gen_odds)

  take(lazy_odds, 5)
  |> should.equal(["1", "3", "5", "7", "9"])
  gen(gen_odds, 5)
  |> pair.first
  |> should.equal(["1", "3", "5", "7", "9"])
  take(lazy_odds_2, 5)
  |> should.equal(["1", "3", "5", "7", "9"])
}

pub fn infinite_test() {
  let gen_nat = infinite(1, fn(x) { #(x, x + 1) })
  gen(gen_nat, 5).0
  |> should.equal([1, 2, 3, 4, 5])
}

pub fn chain_test() {
  let gen_three =
    Generator(1, fn(x) {
      case x <= 3 {
        True -> option.Some(#(x, x + 1))
        False -> option.None
      }
    })
  let gen_nat = infinite(1, fn(x) { #(x, x + 1) })
  // Once the first generator ends, the second one begins
  let gen_chain = chain([gen_three, gen_nat])
  gen_chain
  |> gen(8)
  |> pair.first
  |> should.equal([1, 2, 3, 1, 2, 3, 4, 5])
}

pub fn monad_test() {
  let plus_one = infinite(1, fn(x) { #(x, x + 1) })
  let plus_two = infinite(1, fn(x) { #(x, x + 2) })
  let g = {
    use x <- monad().bind(plus_one)
    use y <- monad().map(plus_two)
    x + y
  }
  g |> gen(5) |> pair.first |> should.equal([3, 9, 15, 21, 27])
}

pub type Wallet {
  Empty
  Money(Int)
  Full
}

pub fn wallet_test() {
  let big_stock =
    Generator(Money(5), fn(w) {
      case w {
        Money(x) -> option.Some(#(x, Money(x * 2)))
        _ -> option.None
      }
    })
  let small_stock =
    Generator(Empty, fn(w) {
      case w {
        Money(x) -> option.Some(#(x + 2, Money(x - 6)))
        _ -> option.None
      }
    })
  let limit =
    Generator(Empty, fn(w) {
      case w {
        Money(x) ->
          case x < 0 || x > 15 {
            False -> option.Some(#(x, w))
            True -> option.None
          }
        _ -> option.None
      }
    })
  let wallet = {
    use x <- monad().bind(big_stock)
    use y <- monad().bind(small_stock)
    use _ <- monad().map(limit)
    int.to_string(x) <> " -> " <> int.to_string(y)
  }
  wallet |> while |> should.equal(["5 -> 12", "4 -> 10"])
}

import gens.{drop, filter, list_zip, map, new, take, zip}
import gleam/int
import gleam/option
import gleeunit
import gleeunit/should

pub fn main() -> Nil {
  gleeunit.main()
}

// Basic test for the default takeerator and the take function
pub fn take_test() {
  assert take(new(), 0) == []
  assert take(new(), 1) == [0]
  assert new() |> take(5) == [0, 1, 2, 3, 4]
}

// Testing the map function for the takeerator type
pub fn map_test() {
  assert new()
    |> map(fn(x) { x + 3 })
    |> map(int.to_string)
    |> take(5)
    == ["3", "4", "5", "6", "7"]
}

// Testing the filter function for the takeerator type
pub fn filter_test() {
  assert new()
    |> filter(fn(x) { x % 2 == 0 })
    |> filter(fn(x) { x != 4 })
    |> take(5)
    == [0, 2, 6, 8, 10]
}

// Testing the drop function for the takeerator type
pub fn drop_test() {
  assert new()
    |> drop(0)
    |> take(1)
    == [0]
  assert new()
    |> drop(1)
    |> take(1)
    == [1]
  assert new()
    |> drop(4)
    |> filter(int.is_even)
    |> take(5)
    == [4, 6, 8, 10, 12]
  assert new()
    |> filter(int.is_even)
    |> drop(4)
    |> take(5)
    == [8, 10, 12, 14, 16]
}

// Testing the zip function for 2 lazy lists
pub fn zip_test() {
  let g1 = new() |> map(fn(x) { x + 2 })
  let g2 = new() |> filter(int.is_even)
  assert zip(g1, g2)
    |> take(3)
    == [#(2, 0), #(4, 2), #(6, 4)]
}

// Testing the list_zip function
pub fn list_zip_test() {
  assert ["a", "b", "c"] |> list_zip(new()) == [#("a", 0), #("b", 1), #("c", 2)]
}

// Testing the get function for generator
pub fn get_test() {
  let counter =
    gens.Generator(state: 0, next: fn(c) { option.Some(#(c, c + 1)) })

  case gens.get(counter).0 {
    option.None -> Nil
    option.Some(x) -> should.equal(x, 0)
  }
}

// Testing the gen function for generator
pub fn gen_test() {
  let counter =
    gens.Generator(state: 0, next: fn(c) { option.Some(#(c, c + 1)) })

  let #(nums, _) = gens.gen(counter, 5)
  nums |> should.equal([0, 1, 2, 3, 4])
}

// Testing the combine function of 2 gens
pub fn combine_test() {
  let two_powers =
    gens.Generator(state: 1, next: fn(p) { option.Some(#(p, p * 2)) })
  let bellow_three =
    gens.Generator(state: 0, next: fn(n) { option.Some(#(n < 3, n + 1)) })

  let z = gens.combine(two_powers, bellow_three)
  let #(res, _) = gens.gen(z, 5)
  should.equal(res, [
    #(1, True),
    #(2, True),
    #(4, True),
    #(8, False),
    #(16, False),
  ])
}

// Testing the from_list function for generator
pub fn from_list_test() {
  let gen_fruit = gens.from_list(["apple", "banana", "orange"])
  let #(fruit1, gen_fruit2) = gens.get(gen_fruit)
  should.equal(fruit1, option.Some("apple"))
  let #(fruit2, gen_fruit3) = gens.get(gen_fruit2)
  should.equal(fruit2, option.Some("banana"))
  let #(fruit3, gen_fruit4) = gens.get(gen_fruit3)
  should.equal(fruit3, option.Some("orange"))
  let #(fruit4, _) = gens.get(gen_fruit4)
  should.equal(fruit4, option.None)
}

// Testing the list_repeat function for generator
pub fn list_repeat_test() {
  let gen_fruit = gens.list_repeat(["apple", "banana", "orange"])
  let #(fruits, _) = gens.gen(gen_fruit, 5)
  should.equal(fruits, ["apple", "banana", "orange", "apple", "banana"])
}

pub fn from_lazy_list_test() {
  let infinite_list = new() |> drop(3) |> map(fn(x) { x * 10 })
  let ten_gen = gens.from_lazy_list(infinite_list)
  let #(res, _) = gens.gen(ten_gen, 10)
  echo res
}

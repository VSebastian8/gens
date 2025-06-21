import gens.{gen, new}
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

// Basic test for the default generator and the gen function
pub fn gen_test() {
  assert gen(new(), 0) == []
  assert gen(new(), 1) == [0]
  assert new() |> gen(5) == [0, 1, 2, 3, 4]
}

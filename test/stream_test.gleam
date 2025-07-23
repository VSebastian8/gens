import gens/stream.{type Stream, Stream, take}
import gleeunit/should

pub fn ones() -> Stream(Int) {
  Stream(head: fn() { 1 }, tail: ones)
}

pub fn stream_test() {
  ones()
  |> take(5)
  |> should.equal([1, 1, 1, 1, 1])
}

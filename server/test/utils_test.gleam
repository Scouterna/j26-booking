import gleeunit/should
import server/utils

pub fn ensure_non_negative_with_positive_integer_test() {
  utils.ensure_non_negative(5)
  |> should.equal(Ok(5))
}

pub fn ensure_non_negative_with_zero_test() {
  utils.ensure_non_negative(0)
  |> should.equal(Ok(0))
}

pub fn ensure_non_negative_with_negative_integer_test() {
  utils.ensure_non_negative(-1)
  |> should.equal(Error(Nil))
}

pub fn ensure_non_negative_with_large_positive_test() {
  utils.ensure_non_negative(1_000_000)
  |> should.equal(Ok(1_000_000))
}

pub fn ensure_non_negative_with_large_negative_test() {
  utils.ensure_non_negative(-1_000_000)
  |> should.equal(Error(Nil))
}

pub fn ensure_non_negative(i: Int) -> Result(Int, Nil) {
  case i {
    natural if i >= 0 -> Ok(natural)
    _ -> Error(Nil)
  }
}

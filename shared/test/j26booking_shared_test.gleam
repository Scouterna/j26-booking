import gleam/dynamic/decode
import gleam/json
import gleeunit
import shared/utils

pub fn main() -> Nil {
  gleeunit.main()
}

pub type Person {
  Person(name: String, age: Int)
}

fn person_decoder() -> decode.Decoder(Person) {
  use name <- decode.field("name", decode.string)
  use age <- decode.field("age", decode.int)
  decode.success(Person(name:, age:))
}

pub fn partial_list_decode_with_invalid_element_test() {
  let json_string =
    "[{\"name\":\"Alice\",\"age\":30},{\"name\":\"Bob\",\"age\":\"not_a_number\"},{\"name\":\"Charlie\",\"age\":25}]"

  let result =
    json.parse(json_string, utils.decode_partial_list(of: person_decoder()))

  let assert Ok([Person("Alice", 30), Person("Charlie", 25)]) = result
}

import gleam/list
import pog

pub fn map_returned_rows(
  over returned: pog.Returned(a),
  with fun: fn(a) -> b,
) -> List(b) {
  list.map(returned.rows, fun)
}

import gleam/dynamic/decode
import gleam/result

pub fn decode_partial_list(
  of inner: decode.Decoder(a),
) -> decode.Decoder(List(a)) {
  decode.list(
    of: decode.one_of(inner |> decode.map(Ok), or: [
      decode.success(Error(Nil)),
    ]),
  )
  |> decode.map(result.values)
}

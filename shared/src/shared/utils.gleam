import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json.{type Json}
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

/// Decode arbitrary JSON into a re-encodable `Json` value without imposing a
/// schema. Use this to carry an opaque JSON blob (e.g. a stored `jsonb` column)
/// through to an API response untouched. `decode.recursive` defers the
/// self-reference so the decoder can describe nested arrays and objects.
///
/// JSON `null` is not handled (it falls through to a decode failure); callers
/// passing through data that may contain nulls should provide a fallback.
pub fn json_passthrough_decoder() -> decode.Decoder(Json) {
  use <- decode.recursive
  decode.one_of(decode.string |> decode.map(json.string), or: [
    decode.bool |> decode.map(json.bool),
    decode.int |> decode.map(json.int),
    decode.float |> decode.map(json.float),
    decode.list(json_passthrough_decoder())
      |> decode.map(json.preprocessed_array),
    decode.dict(decode.string, json_passthrough_decoder())
      |> decode.map(dict_to_json),
  ])
}

fn dict_to_json(entries: Dict(String, Json)) -> Json {
  entries |> dict.to_list |> json.object
}

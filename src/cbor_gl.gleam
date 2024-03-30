import gleam/bit_array.{to_string}
import gleam/result.{try}

pub opaque type CborError {
  /// Indicates the input ended prematurely and decoding could not continue.
  PrematureEOF
  Encode
  /// This indicates that the major type in the payload was one that is not
  /// valid according to the CBOR specification. See RFC 8949 section 3.
  InvalidMajorArg(Int)
  /// Indicates the type decoded did not match the expected type.
  IncorrectType(
    /// the major_type is the CBOR Section 3.1 Major Types indicator.
    major_type: Int,
  )
  MalformedUTF8
}

type DecodeResult(t) =
  Result(#(t, BitArray), CborError)

pub fn decode_int(a: BitArray) -> DecodeResult(Int) {
  case a {
    <<0:3, rest:bits>> -> decode_positive_int(rest)
    <<1:3, rest:bits>> -> decode_negative_int(rest)
    <<_:3>> -> Error(PrematureEOF)
    <<x:3, _:bits>> -> Error(IncorrectType(major_type: x))
    _ -> Error(PrematureEOF)
  }
}

fn decode_positive_int(a: BitArray) -> DecodeResult(Int) {
  case a {
    <<24:int-size(5), val:int-unsigned-size(8), rest:bits>> -> Ok(#(val, rest))
    <<25:int-size(5), val:int-unsigned-size(16), rest:bits>> -> Ok(#(val, rest))
    <<26:int-size(5), val:int-unsigned-size(32), rest:bits>> -> Ok(#(val, rest))
    <<27:int-size(5), val:int-unsigned-size(64), rest:bits>> -> Ok(#(val, rest))
    <<x:int-size(5), _:bits>> if 27 < x -> Error(InvalidMajorArg(x))
    <<x:int-size(5), rest:bits>> if x < 24 -> Ok(#(x, rest))
    _ -> Error(PrematureEOF)
  }
}

fn decode_negative_int(a: BitArray) -> DecodeResult(Int) {
  case a {
    <<24:int-size(5), val:int-unsigned-size(8), rest:bits>> ->
      Ok(#(1 - val, rest))
    <<25:int-size(5), val:int-unsigned-size(16), rest:bits>> ->
      Ok(#(1 - val, rest))
    <<26:int-size(5), val:int-unsigned-size(32), rest:bits>> ->
      Ok(#(1 - val, rest))
    <<27:int-size(5), val:int-unsigned-size(64), rest:bits>> ->
      Ok(#(1 - val, rest))
    <<x:int-size(5), rest:bits>> if x < 24 -> Ok(#(1 - x, rest))
    <<x:int-size(5), _:bits>> if 27 < x -> Error(InvalidMajorArg(x))
    _ -> Error(PrematureEOF)
  }
}

/// Decodes an array of bytes
pub fn decode_bytes(a: BitArray) -> DecodeResult(BitArray) {
  case a {
    <<2:3, rest:bits>> -> {
      use #(count, rest) <- try(decode_positive_int(rest))
      case rest {
        <<x:bytes-size(count), rest:bits>> -> Ok(#(x, rest))
        _ -> Error(PrematureEOF)
      }
    }
    // TODO: handle indefinite sized bytes
    <<x:3, _:bits>> -> Error(InvalidMajorArg(x))
    _ -> Error(PrematureEOF)
  }
}

pub fn decode_string(a: BitArray) -> DecodeResult(String) {
  case a {
    <<3:3, rest:bits>> ->
      case decode_positive_int(rest) {
        Error(e) -> Error(e)
        Ok(#(count, rest)) ->
          case rest {
            <<x:bytes-size(count), rest:bits>> ->
              case to_string(x) {
                Ok(s) -> Ok(#(s, rest))
                Error(_) -> Error(MalformedUTF8)
              }
            _ -> Error(PrematureEOF)
          }
      }
    <<x:3, _:bits>> -> Error(InvalidMajorArg(x))
    _ -> Error(PrematureEOF)
  }
}

/// Decodes a homogenous array or list of items from BitArray using the
/// provided callback function.
//pub fn decode_list(
//  a: BitArray,
//  f: fn(BitArray) -> DecodeResult(t),
//) -> DecodeResult(List(t)) {
//  case a {
//    <<4:3, rest:bits>> -> {
//      use #(count, rest) <- try(decode_positive_int(rest))
//      use result <- try(
//        iterator.range(from: 0, to: count)
//        |> iterator.transform(rest, fn(b, _) {
//          try(f(b)
//          todo
//        }),
//      )
//    }
//  }
//}
//
//fn decode_list_item(
//  a: BitArray,
//  count: Int,
//  f: fn(BitArray) -> DecodeResult(List(t)),
//) {
//  use #(item, rest) <- try(f(a))
//  case count {
//    x -> [item, ..decode_list_item(rest, x - 1, f)]
//    0 -> []
//  }
//}

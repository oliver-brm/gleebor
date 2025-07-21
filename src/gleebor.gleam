import gleam/bit_array.{to_string}
import gleam/result.{map, replace_error, try}
import gleam/yielder.{type Step, type Yielder, Done, Next}

pub type CborError {
  /// Indicates the input ended prematurely and decoding could not continue.
  PrematureEOF
  /// Indicates that the major type decoded did not match the expected type.
  IncorrectType(
    /// the `major_type` is represented as the first 3 bits of a CBOR data item.
    /// An overview is provided in in the CBOR spec, section 3.1, see also
    /// [Table 1](https://www.rfc-editor.org/rfc/rfc8949.html#major-type-table) therein.
    major_type: Int,
  )
  /// Indicates that the argument in the payload was one that is not
  /// valid according to the CBOR specification. See RFC 8949 section 3.
  InvalidMajorArg(
    /// the `major_arg` is represented as the 5 bits following the _major type_.
    major_arg: Int,
  )
  MalformedUTF8
}

type DecodeResult(t) =
  Result(#(t, BitArray), CborError)

/// Decodes an integer value. CBOR integer values are described by the value in the
/// first three bits, the following five bits and, optionally, the next up to 8 bytes.
/// The table below summarizes the rules by which CBOR integer values should be encoded
/// in order to get properly read.
/// 
/// | bits 1-3 | bits 5-8       | explanation                                                                   |
/// |----------|----------------|-------------------------------------------------------------------------------|
/// | 0        | 0-23           | Positive integer values 0 to 23                                               |
/// | 0        | 24, 25, 26, 27 | Positive integer, the value is in the next 1, 2, 4 or 8 bytes respectively    |
/// | 1        | 0-23           | Negative integer values -1 to -24                                             |
/// | 1        | 24, 25, 26, 27 | Negative integer, the value is -1 - <the value in the next 1, 2, 4 or 8 bytes |
///
/// Returns a `Result`. The `Ok` value contains a `Pair` of the decoded integer value and the rest of
/// the provided `BitArray`. The `Error` value contains a [CborError](#CborError).
///
/// ## Examples
/// ```gleam
/// gleebor.decode_int(<<0:3, 0:5>>)         // ==   0
/// gleebor.decode_int(<<0:3, 24:5, 255:8>>) // == 255
/// gleebor.decode_int(<<0:3, 25:5, 256:8>>) // == 256
/// gleebor.decode_int(<<1:3, 7:5>>)         // ==  -8
/// gleebor.decode_int(<<1:3, 24:5, 41:8>>)  // == -42
/// ```
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
      Ok(#(-1 - val, rest))
    <<25:int-size(5), val:int-unsigned-size(16), rest:bits>> ->
      Ok(#(-1 - val, rest))
    <<26:int-size(5), val:int-unsigned-size(32), rest:bits>> ->
      Ok(#(-1 - val, rest))
    <<27:int-size(5), val:int-unsigned-size(64), rest:bits>> ->
      Ok(#(-1 - val, rest))
    <<x:int-size(5), rest:bits>> if x < 24 -> Ok(#(-1 - x, rest))
    <<x:int-size(5), _:bits>> if 27 < x -> Error(InvalidMajorArg(x))
    _ -> Error(PrematureEOF)
  }
}

/// Decodes an array of bytes, called a byte string in
/// [RFC 8949](https://www.rfc-editor.org/rfc/rfc8949.html#section-3.1-2.5).
/// A byte string has the major type 2 (first 3 bits).
///
/// The next 5 bits are a number which describes either the length of 0 to
/// 23 bytes, or, if the length of the byte string is greater than 23 bytes, these
/// five bits form a regular _integer argument_, i.e. either 24, 25, 26 or 27,
/// describing that the next 1, 2, 4 or 8 bytes are the _size_ integer value.
/// See [decode_int](#decode_int) for the rules of an integer value.
///
/// After these 5 - 69 bits must be the content of `8 x <length>` bits. A content
/// shorter than declared results in a [`PrematureEOF`](#CborError) error.
///
/// This function returns a `Result` with the `Ok` value containing a `Pair` of
/// the decoded byte string, represented as a `BitArray`, and the rest of the
/// given `BitArray`. The `Error` value contains a [CborError](#CborError).
///
/// ## Examples
/// ```gleam
/// // byte string of length 6
/// let byte_string = <<4:8, 8:8, 15:8, 16:8, 23:8, 42:8>> 
/// // major type 2, argument 6 (length)
/// let cbor = <<2:3, 6:5, byte_string:bits>>              
/// assert decode_bytes(cbor) == Ok(byte_string, <<>>) // True
/// ```
pub fn decode_bytes(a: BitArray) -> DecodeResult(BitArray) {
  case a {
    <<2:3, 24:5, s:int-unsigned-size(8), val:bytes-size(s), rest:bits>> ->
      Ok(#(val, rest))
    <<2:3, 25:5, s:int-unsigned-size(16), val:bytes-size(s), rest:bits>> ->
      Ok(#(val, rest))
    <<2:3, 26:5, s:int-unsigned-size(32), val:bytes-size(s), rest:bits>> ->
      Ok(#(val, rest))
    <<2:3, 27:5, s:int-unsigned-size(64), val:bytes-size(s), rest:bits>> ->
      Ok(#(val, rest))
    <<2:3, s:int-unsigned-size(5), val:bytes-size(s), rest:bits>> ->
      Ok(#(val, rest))
    <<2:3, 31:5, data:bits>> -> decode_indefinite_bytes(data, <<>>)
    <<2:3, a:5, _>> if a < 31 -> Error(InvalidMajorArg(a))
    <<m:3, _:bits>> -> Error(IncorrectType(major_type: m))
    _ -> Error(PrematureEOF)
  }
}

fn decode_indefinite_bytes(b: BitArray, acc: BitArray) -> DecodeResult(BitArray) {
  case b {
    // The spec does not allow nesting for byte strings and text strings
    <<2:3, 31:5, _:bits>> -> Error(InvalidMajorArg(31))
    // The "break" stop code, break recursion and return the accumulated data
    <<7:3, 31:5, rest:bits>> -> Ok(#(acc, rest))
    chunks -> {
      use #(data_item, rest) <- try(decode_bytes(chunks))
      decode_indefinite_bytes(
        rest,
        bit_array.append(to: acc, suffix: data_item),
      )
    }
  }
}

pub fn decode_string(a: BitArray) -> DecodeResult(String) {
  case a {
    <<3:3, rest:bits>> -> {
      use #(count, rest) <- try(decode_positive_int(rest))
      case rest {
        <<x:bytes-size(count), rest:bits>> -> {
          use s <- try(replace_error(to_string(x), MalformedUTF8))
          Ok(#(s, rest))
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
pub fn decode_list(
  buffer a: BitArray,
  with f: fn(BitArray) -> DecodeResult(t),
) -> Result(Yielder(DecodeResult(t)), CborError) {
  case a {
    <<4:3, rest:bits>> -> {
      use #(count, rest) <- try(decode_positive_int(rest))
      // TODO: refactor this to be less ugly
      Ok(
        yielder.unfold(#(count, rest), fn(n: #(Int, BitArray)) -> Step(
          DecodeResult(t),
          #(Int, BitArray),
        ) {
          case n {
            #(0, _) -> Done
            #(remaining, rest) ->
              case f(rest) {
                Ok(#(result, rest)) ->
                  Next(Ok(#(result, rest)), #(remaining - 1, rest))
                Error(e) -> {
                  // Yield the error, and prevent from continuing
                  Next(Error(e), #(0, rest))
                }
              }
          }
        }),
      )
    }
    <<x:3, _:bits>> -> Error(InvalidMajorArg(x))
    _ -> Error(PrematureEOF)
  }
}

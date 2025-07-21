import gleam/bit_array
import gleam/list
import gleam/result
import gleebor
import gleeunit

pub fn main() {
  gleeunit.main()
}

pub fn decode_simple_number_test() {
  assert gleebor.decode_int(<<0:3, 13:5>>) == Ok(#(13, <<>>))
  assert gleebor.decode_int(<<0:3>>) == Error(gleebor.PrematureEOF)
}

pub fn decode_int_wrong_argument_test() {
  [28, 29, 30, 31]
  |> list.each(fn(argument) {
    assert gleebor.decode_int(<<0:3, argument:5, 42:8>>)
      == Error(gleebor.InvalidMajorArg(argument))
  })
}

pub fn decode_u8_test() {
  assert gleebor.decode_int(<<0:3, 24:5, 7:8>>) == Ok(#(7, <<>>))
  assert gleebor.decode_int(<<0:3, 24:5, 255:8>>) == Ok(#(255, <<>>))
  assert gleebor.decode_int(<<0:3, 24:5>>) == Error(gleebor.PrematureEOF)
}

pub fn decode_u16_test() {
  assert gleebor.decode_int(<<0:3, 25:5, 6:16>>) == Ok(#(6, <<>>))
  assert gleebor.decode_int(<<0:3, 25:5, 256:16>>) == Ok(#(256, <<>>))
  assert gleebor.decode_int(<<0:3, 25:5, 6:8>>) == Error(gleebor.PrematureEOF)
}

pub fn decode_u32_test() {
  assert gleebor.decode_int(<<0:3, 26:5, 5:32>>) == Ok(#(5, <<>>))
  assert gleebor.decode_int(<<0:3, 26:5, 5:16>>) == Error(gleebor.PrematureEOF)
}

pub fn decode_u64_test() {
  assert gleebor.decode_int(<<0:3, 27:5, 4:64>>) == Ok(#(4, <<>>))
  assert gleebor.decode_int(<<0:3, 27:5, 4:32>>) == Error(gleebor.PrematureEOF)
}

pub fn decode_simple_negative_number_test() {
  assert gleebor.decode_int(<<1:3, 11:5>>) == Ok(#(-12, <<>>))
  assert gleebor.decode_int(<<1:3>>) == Error(gleebor.PrematureEOF)
}

pub fn decode_negative_u8_test() {
  assert gleebor.decode_int(<<1:3, 24:5, 7:8>>) == Ok(#(-8, <<>>))
  assert gleebor.decode_int(<<1:3, 24:5>>) == Error(gleebor.PrematureEOF)
}

pub fn decode_negative_u16_test() {
  assert gleebor.decode_int(<<1:3, 25:5, 4:16>>) == Ok(#(-5, <<>>))
  // Example from the spec, see https://www.rfc-editor.org/rfc/rfc8949.html#name-major-types
  assert gleebor.decode_int(<<1:3, 25:5, 499:16>>) == Ok(#(-500, <<>>))
  assert gleebor.decode_int(<<1:3, 25:5, 6:8>>) == Error(gleebor.PrematureEOF)
}

pub fn decode_negative_u32_test() {
  assert gleebor.decode_int(<<1:3, 26:5, 4:32>>) == Ok(#(-5, <<>>))
  assert gleebor.decode_int(<<1:3, 26:5, 5:16>>) == Error(gleebor.PrematureEOF)
}

pub fn decode_negative_u64_test() {
  assert gleebor.decode_int(<<1:3, 27:5, 4:64>>) == Ok(#(-5, <<>>))
  assert gleebor.decode_int(<<1:3, 27:5, 4:32>>) == Error(gleebor.PrematureEOF)
}

pub fn decode_byte_string_test() {
  // some small byte arrays
  [
    #(1, <<123>>),
    #(6, <<4:8, 8:8, 15:8, 16:8, 23:8, 42:8>>),
    #(0, <<>>),
    #(23, <<1:184>>),
  ]
  |> list.each(fn(data) {
    let #(length, byte_string) = data
    assert gleebor.decode_bytes(<<2:3, length:5, byte_string:bits>>)
      == Ok(#(byte_string, <<>>))
  })
}

/// This checks if a wrong _length_ argument, which should be in [0-27, 31],
/// results in an `InvalidMajorArg(wrong_length)` `Error`.
pub fn decode_byte_string_wrong_major_arg_test() {
  [28, 29, 30]
  |> list.each(fn(length) {
    assert gleebor.decode_bytes(<<2:3, length:5, 239>>)
      == Error(gleebor.InvalidMajorArg(length))
  })
}

pub fn decode_byte_string_wrong_major_type_test() {
  [0, 1, 3, 4, 5, 6, 7]
  |> list.each(fn(wrong_type) {
    assert gleebor.decode_bytes(<<wrong_type:3, 8:5, 12_345:64>>)
      == Error(gleebor.IncorrectType(major_type: wrong_type))
  })
}

pub fn decode_large_byte_string_test() {
  // a larger one, 32 bytes of data
  let data = <<
    78:int-size(64), 78:int-size(64), 78:int-size(64), 78:int-size(64),
  >>
  let large_byte_string = <<2:3, 24:5, 32:8, data:bits>>
  assert gleebor.decode_bytes(large_byte_string) == Ok(#(data, <<>>))
}

pub fn decode_indefinite_byte_string_test() {
  let chunk1 = <<2:3, 4:5, 2_864_434_397:32>>
  let chunk2 = <<2:3, 3:5, 15_663_001:24>>
  let break = <<7:3, 31:5>>
  let cbor = <<2:3, 31:5, chunk1:bits, chunk2:bits, break:bits>>
  use expected <- result.map(bit_array.base16_decode("aabbccddeeff99"))
  assert gleebor.decode_bytes(cbor) == Ok(#(expected, <<>>))
}

pub fn decode_uft8_string_test() {
  // an empty text string
  assert gleebor.decode_string(<<3:3, 0:5>>) == Ok(#("", <<>>))
  // a small text string, in fact only a single letter
  assert gleebor.decode_string(<<3:3, 1:5, "N":utf8>>) == Ok(#("N", <<>>))
  // a larger one, uses a u8
  let expected = "Hello, world! This is a long string!"
  let large_string = <<3:3, 24:5, 36:8, expected:utf8>>
  assert gleebor.decode_string(large_string) == Ok(#(expected, <<>>))
}

import gleebor
import gleeunit

pub fn main() {
  gleeunit.main()
}

pub fn decode_simple_number_test() {
  assert gleebor.decode_int(<<0:3, 13:5>>) == Ok(#(13, <<>>))
  assert gleebor.decode_int(<<0:3>>) == Error(gleebor.PrematureEOF)
}

pub fn decode_u8_test() {
  assert gleebor.decode_int(<<0:3, 24:5, 7:8>>) == Ok(#(7, <<>>))
  assert gleebor.decode_int(<<0:3, 24:5>>) == Error(gleebor.PrematureEOF)
}

pub fn decode_u16_test() {
  assert gleebor.decode_int(<<0:3, 25:5, 6:16>>) == Ok(#(6, <<>>))
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
  // a small byte array
  assert gleebor.decode_bytes(<<2:3, 1:5, 123>>) == Ok(#(<<123>>, <<>>))
  // a larger one, uses a u8
  let large_byte_string = <<
    2:3, 24:5, 32:8, 78:int-size(64), 78:int-size(64), 78:int-size(64),
    78:int-size(64),
  >>
  let expected = <<
    78:int-size(64), 78:int-size(64), 78:int-size(64), 78:int-size(64),
  >>
  assert gleebor.decode_bytes(large_byte_string) == Ok(#(expected, <<>>))
}

pub fn decode_uft8_string_test() {
  // a small byte array
  assert gleebor.decode_string(<<3:3, 1:5, "N":utf8>>) == Ok(#("N", <<>>))
  // a larger one, uses a u8
  let large_string = <<
    3:3, 24:5, 36:8, "Hello, world! This is a long string!":utf8,
  >>
  let expected = "Hello, world! This is a long string!"
  assert gleebor.decode_string(large_string) == Ok(#(expected, <<>>))
}

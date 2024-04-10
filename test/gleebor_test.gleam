import gleebor
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn decode_simple_number_test() {
  gleebor.decode_int(<<0:3, 13:5>>)
  |> should.be_ok()
  |> should.equal(#(13, <<>>))
  gleebor.decode_int(<<0:3>>)
  |> should.be_error()
}

pub fn decode_u8_test() {
  gleebor.decode_int(<<0:3, 24:5, 7:8>>)
  |> should.be_ok()
  |> should.equal(#(7, <<>>))
  gleebor.decode_int(<<0:3, 24:5>>)
  |> should.be_error()
}

pub fn decode_u16_test() {
  gleebor.decode_int(<<0:3, 25:5, 6:16>>)
  |> should.be_ok()
  |> should.equal(#(6, <<>>))
  gleebor.decode_int(<<0:3, 25:5, 6:8>>)
  |> should.be_error()
}

pub fn decode_u32_test() {
  gleebor.decode_int(<<0:3, 26:5, 5:32>>)
  |> should.be_ok()
  |> should.equal(#(5, <<>>))
  gleebor.decode_int(<<0:3, 26:5, 5:16>>)
  |> should.be_error()
}

pub fn decode_u64_test() {
  gleebor.decode_int(<<0:3, 27:5, 4:64>>)
  |> should.be_ok()
  |> should.equal(#(4, <<>>))
  gleebor.decode_int(<<0:3, 27:5, 4:32>>)
  |> should.be_error()
}

pub fn decode_simple_negative_number_test() {
  gleebor.decode_int(<<1:3, 13:5>>)
  |> should.be_ok()
  |> should.equal(#(-12, <<>>))
  gleebor.decode_int(<<1:3>>)
  |> should.be_error()
}

pub fn decode_negative_u8_test() {
  gleebor.decode_int(<<1:3, 24:5, 7:8>>)
  |> should.be_ok()
  |> should.equal(#(-6, <<>>))
  gleebor.decode_int(<<1:3, 24:5>>)
  |> should.be_error()
}

pub fn decode_negative_u16_test() {
  gleebor.decode_int(<<1:3, 25:5, 6:16>>)
  |> should.be_ok()
  |> should.equal(#(-5, <<>>))
  gleebor.decode_int(<<1:3, 25:5, 6:8>>)
  |> should.be_error()
}

pub fn decode_negative_u32_test() {
  gleebor.decode_int(<<1:3, 26:5, 5:32>>)
  |> should.be_ok()
  |> should.equal(#(-4, <<>>))
  gleebor.decode_int(<<1:3, 26:5, 5:16>>)
  |> should.be_error()
}

pub fn decode_negative_u64_test() {
  gleebor.decode_int(<<1:3, 27:5, 4:64>>)
  |> should.be_ok()
  |> should.equal(#(-3, <<>>))
  gleebor.decode_int(<<1:3, 27:5, 4:32>>)
  |> should.be_error()
}

pub fn decode_byte_string_test() {
  // a small byte array
  gleebor.decode_bytes(<<2:3, 1:5, 123>>)
  |> should.be_ok()
  |> should.equal(#(<<123>>, <<>>))
  // a larger one, uses a u8
  gleebor.decode_bytes(<<
    2:3, 24:5, 32:8, 78:int-size(64), 78:int-size(64), 78:int-size(64),
    78:int-size(64),
  >>)
  |> should.be_ok()
  |> should.equal(
    #(<<78:int-size(64), 78:int-size(64), 78:int-size(64), 78:int-size(64)>>, <<>>),
  )
}

pub fn decode_uft8_string_test() {
  // a small byte array
  gleebor.decode_string(<<3:3, 1:5, "N":utf8>>)
  |> should.be_ok()
  |> should.equal(#("N", <<>>))
  // a larger one, uses a u8
  gleebor.decode_string(<<
    3:3, 24:5, 36:8, "Hello, world! This is a long string!":utf8,
  >>)
  |> should.be_ok()
  |> should.equal(#("Hello, world! This is a long string!", <<>>))
}

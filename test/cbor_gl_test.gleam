import gleeunit
import gleeunit/should
import cbor_gl

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn decode_simple_number_test() {
  cbor_gl.decode_int(<<0:3, 13:5>>)
  |> should.be_ok()
  |> should.equal(#(13, <<>>))
  cbor_gl.decode_int(<<0:3>>)
  |> should.be_error()
}

pub fn decode_u8_test() {
  cbor_gl.decode_int(<<0:3, 24:5, 7:8>>)
  |> should.be_ok()
  |> should.equal(#(7, <<>>))
  cbor_gl.decode_int(<<0:3, 24:5>>)
  |> should.be_error()
}

pub fn decode_u16_test() {
  cbor_gl.decode_int(<<0:3, 25:5, 6:16>>)
  |> should.be_ok()
  |> should.equal(#(6, <<>>))
  cbor_gl.decode_int(<<0:3, 25:5, 6:8>>)
  |> should.be_error()
}

pub fn decode_u32_test() {
  cbor_gl.decode_int(<<0:3, 26:5, 5:32>>)
  |> should.be_ok()
  |> should.equal(#(5, <<>>))
  cbor_gl.decode_int(<<0:3, 26:5, 5:16>>)
  |> should.be_error()
}

pub fn decode_u64_test() {
  cbor_gl.decode_int(<<0:3, 27:5, 4:64>>)
  |> should.be_ok()
  |> should.equal(#(4, <<>>))
  cbor_gl.decode_int(<<0:3, 27:5, 4:32>>)
  |> should.be_error()
}

pub fn decode_simple_negative_number_test() {
  cbor_gl.decode_int(<<1:3, 13:5>>)
  |> should.be_ok()
  |> should.equal(#(-12, <<>>))
  cbor_gl.decode_int(<<1:3>>)
  |> should.be_error()
}

pub fn decode_negative_u8_test() {
  cbor_gl.decode_int(<<1:3, 24:5, 7:8>>)
  |> should.be_ok()
  |> should.equal(#(-6, <<>>))
  cbor_gl.decode_int(<<1:3, 24:5>>)
  |> should.be_error()
}

pub fn decode_negative_u16_test() {
  cbor_gl.decode_int(<<1:3, 25:5, 6:16>>)
  |> should.be_ok()
  |> should.equal(#(-5, <<>>))
  cbor_gl.decode_int(<<1:3, 25:5, 6:8>>)
  |> should.be_error()
}

pub fn decode_negative_u32_test() {
  cbor_gl.decode_int(<<1:3, 26:5, 5:32>>)
  |> should.be_ok()
  |> should.equal(#(-4, <<>>))
  cbor_gl.decode_int(<<1:3, 26:5, 5:16>>)
  |> should.be_error()
}

pub fn decode_negative_u64_test() {
  cbor_gl.decode_int(<<1:3, 27:5, 4:64>>)
  |> should.be_ok()
  |> should.equal(#(-3, <<>>))
  cbor_gl.decode_int(<<1:3, 27:5, 4:32>>)
  |> should.be_error()
}

pub fn decode_byte_string_test() {
  // a small byte array
  cbor_gl.decode_bytes(<<2:3, 1:5, 123>>)
  |> should.be_ok()
  |> should.equal(#(<<123>>, <<>>))
  // a larger one, uses a u8
  cbor_gl.decode_bytes(<<2:3, 24:5, 32:8, 78:int-size(64), 78:int-size(64), 78:int-size(64), 78:int-size(64)>>)
  |> should.be_ok()
  |> should.equal(#(<<78:int-size(64), 78:int-size(64), 78:int-size(64), 78:int-size(64)>>, <<>>))
}

pub fn decode_uft8_string_test() {
  // a small byte array
  cbor_gl.decode_string(<<3:3, 1:5, "N":utf8>>)
  |> should.be_ok()
  |> should.equal(#("N", <<>>))
  // a larger one, uses a u8
  cbor_gl.decode_string(<<3:3, 24:5, 36:8, "Hello, world! This is a long string!":utf8>>)
  |> should.be_ok()
  |> should.equal(#("Hello, world! This is a long string!", <<>>))
}

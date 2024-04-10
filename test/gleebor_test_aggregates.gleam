import gleebor
import gleam/iterator
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
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

pub fn decode_list_ints_test() {
  gleebor.decode_list(<<4:3, 3:5, 5:8, 4:8, 3:8>>, with: gleebor.decode_int)
  |> should.be_ok()
  |> iterator.map(fn(r) {
    let #(val, _) = should.be_ok(r)
    val
  })
  |> iterator.to_list
  |> should.equal([5, 4, 3])
}

pub fn decode_list_strings_failure_test() {
  gleebor.decode_list(<<4:3, 3:5, 5:8, 4:8, 3:8>>, with: gleebor.decode_string)
  |> should.be_ok()
  |> iterator.first()
  |> should.be_ok()
  |> should.be_error()
  |> should.equal(gleebor.InvalidMajorArg(0))
}

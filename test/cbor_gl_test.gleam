import gleeunit
import gleeunit/should
import cbor_gl

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  let x = cbor_gl.encode("Hello, world")
  let x2 = cbor_gl.decode(x)
  should.equal(x, x2)
}

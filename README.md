# CBOR

### A RFC 8949 Library for Gleam

[![Package Version](https://img.shields.io/hexpm/v/cbor)](https://hex.pm/packages/cbor)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/cbor/)

```sh
gleam add cbor
```
```gleam
import cbor
import io

fn read_my_bytes() {
  // 0 major arg, 24 to signal the following byte is the payload value, 123 is an 8-bit
  //number
  <<0:3, 24:5, 123:8>>
}

pub fn main() {
  // Get your bytes somehow!
  let bytes = read_my_bytes()

  let assert Ok(number) = cbor.decode_int(bytes)
  io.debug(number) // => 123
}
```

Further documentation can be found at <https://hexdocs.pm/cbor>.

## Development

```sh
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

## Status

The following describes the current status for this library's progress.


- [/] Decode
  - [x] Ints
  - [ ] Floats
  - [x] Text Strings (Sized)
  - [x] Bytes (sized)
  - [x] Arrays (sized)
  - [ ] Maps
  - [ ] Tags
  - [ ] Indefinite sequences
- [ ] Encode
  - [ ] Ints
  - [ ] Floats
  - [ ] Text Strings (Sized)
  - [ ] Bytes (sized)
  - [ ] Arrays (sized)
  - [ ] Maps
  - [ ] Tags
  - [ ] Indefinite sequences



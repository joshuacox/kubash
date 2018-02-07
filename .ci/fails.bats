#!/usr/bin/env bats

@test "checkbashisms scripts" {
  result="$(checkbashisms -xnp ../scripts/*)"
  [ -z "$result" ]
}

@test "checkbashisms w8s" {
  result="$(checkbashisms -xnp ../w8s/*)"
  [ -z "$result" ]
}

#!/usr/bin/env bats

@test "checkbashisms kubash" {
  result="$(checkbashisms -xnp ./bin/kubash)"
  [ -z "$result" ]
}

@test "checkbashisms bootstrap" {
  result="$(checkbashisms -xnp ./bootstrap)"
  [ -z "$result" ]
}

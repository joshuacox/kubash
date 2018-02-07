#!/usr/bin/env bats

@test "addition using bc" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}

@test "addition using dc" {
  result="$(echo 2 2+p | dc)"
  [ "$result" -eq 4 ]
}

@test "checkbashisms kubash" {
  result="$(checkbashisms -xnp ./bin/kubash)"
  [ -z "$result" ]
}

@test "checkbashisms bootstrap" {
  result="$(checkbashisms -xnp ./bootstrap)"
  [ -z "$result" ]
}

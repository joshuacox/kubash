#!/usr/bin/env bash

horizontal_rule () {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

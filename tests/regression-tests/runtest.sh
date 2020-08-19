#!/bin/bash

set -ex

cmd='/usr/libexec/tests/llvm/run-lit-tests --threads 1'
if [ `id -u` -eq 0 ]; then
  # lit tests can't be run as root, so we need to run as a different user
  user='llvm-regression-tests'
  if ! id -u $user; then
    useradd $user
  fi
  cmd="su $user -c $cmd"
fi
exec $cmd

#!/bin/bash

set -ex

echo "int main() {}" | clang $(llvm-config --cflags) -x c - -o /dev/null

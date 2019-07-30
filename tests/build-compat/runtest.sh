#!/bin/bash

set -ex

env
ls

dnf download --best --source llvm

ls

# The src.rpm is available in the directory the test run from.
mock --with compat_build --rebuild *.src.rpm

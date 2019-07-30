#!/bin/bash

set -ex

dnf download --disablerepo=* --enablerepo=test-llvm --source llvm

# The src.rpm is available in the directory the test run from.
set +e
mock --resultdir=. --old-chroot --with compat_build --rebuild *.src.rpm
if [ $? -ne 0 ]; then
  cat root.log
  cat build.log
  exit 1
fi

exit 0

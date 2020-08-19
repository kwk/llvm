#!/bin/bash

set -ex

test `stat -L -c %s /usr/lib64/libLLVM.so` -lt 100000000

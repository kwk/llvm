#!/bin/bash

set -e
set -x

# Building on tofan

# Login to build host
# ssh tofan

# Start of recover a previous session:
# screen or screen -dr

mkdir -pv /opt/notnfs/$USER/llvm-rpms/tmp
cd /opt/notnfs/$USER/llvm-rpms

# Get the latest git version and shorten it for the snapshot name
LATEST_GIT_SHA=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/llvm/llvm-project/commits | jq -r '.[].sha' | head -1)
LATEST_GIT_SHA_SHORT=${LATEST_GIT_SHA:0:8}
export LLVM_ARCHIVE_URL=https://github.com/llvm/llvm-project/archive/${LATEST_GIT_SHA}.zip
# Get the UTC date in YYYYMMDD format
YYYYMMDD=$(date --date='TZ="UTC"' +'%Y%m%d')
SNAPSHOT_NAME="${YYYYMMDD}git${LATEST_GIT_SHA_SHORT}"
# TODO(kwk): How to integrate the SNAPSHOT_NAME into the RELEASE below?
export RELEASE="%{?rc_ver:0.}%{baserelease}%{?rc_ver:.rc%{rc_ver}}%{?dist}"

# Get LLVM version from CMakeLists.txt
wget -O tmp/CMakeLists.txt https://raw.githubusercontent.com/llvm/llvm-project/${LATEST_GIT_SHA}/llvm/CMakeLists.txt
export LLVM_VERSION_MAJOR=$(grep --regexp="set(\s*LLVM_VERSION_MAJOR" tmp/CMakeLists.txt | tr -d -c '[0-9]')
export LLVM_VERSION_MINOR=$(grep --regexp="set(\s*LLVM_VERSION_MINOR" tmp/CMakeLists.txt | tr -d -c '[0-9]')
export LLVM_VERSION_PATCH=$(grep --regexp="set(\s*LLVM_VERSION_PATCH" tmp/CMakeLists.txt | tr -d -c '[0-9]')
export LLVM_VERSION="${LLVM_MAJOR_VERSION}.${LLVM_MINOR_VERSION}.${LLVM_PATCH_VERSION}"
echo ${LLVM_VERSION}
# Prepare dedicated env vars I'd like to replace inside of the LLVM spec file

export RC_VER=1
export BASERELEASE=1
envsubst '${LLVM_VERSION_MAJOR} ${LLVM_VERSION_MINOR} ${LLVM_VERSION_PATCH} ${LLVM_ARCHIVE_URL} ${RELEASE} ${RC_VER} ${BASERELEASE}' < ./llvm.spec > llvm.spec.out

# Ensure %{_sourcdir} points to a writable location
mkdir -p /opt/notnfs/$USER/rpmbuild/SOURCES
echo '%_topdir /opt/notnfs/$USER/rpmbuild' >> ~/.rpmmacros
# The following should show /opt/notnfs/$USER/rpmbuild/SOURCES
# rpm --eval '%{_sourcedir}'

# Download files from the specfile into the current directory
spectool -R -g -A -C . llvm.spec.out

# Build SRPM
time mock -r k8s-rpmbuilder/home/rawhide.cfg --spec=llvm.spec.out --sources=$PWD --buildsrpm --resultdir=$PWD/tmp/rpms/ --no-cleanup-after --isolation=simple

# Build RPM
# TODO(kwk): Adjust version of file
# time mock -r k8s-rpmbuilder/home/rawhide.cfg --rebuild $PWD/tmp/rpms/llvm-11.1.0-0.3.rc2.fc34.src.rpm --resultdir=$PWD/tmp/rpms/ --no-cleanup-after --isolation=simple
```
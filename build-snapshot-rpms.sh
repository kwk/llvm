#!/bin/bash

# Login to build host (e.g. tofan)
# ssh tofan

# Start of recover a previous session:
# screen or screen -dr

set -eux

# Ensure Bash pipelines (e.g. cmd | othercmd) return a non-zero status if any of
# the commands fail, rather than returning the exit status of the last command
# in the pipeline.
set -o pipefail

mkdir -pv /opt/notnfs/$USER/llvm-rpms/tmp
cd /opt/notnfs/$USER/llvm-rpms

# Get the latest git version and shorten it for the snapshot name
LATEST_GIT_SHA=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/llvm/llvm-project/commits | jq -r '.[].sha' | head -1)
LATEST_GIT_SHA_SHORT=${LATEST_GIT_SHA:0:8}

export LLVM_ARCHIVE_URL=https://github.com/llvm/llvm-project/archive/${LATEST_GIT_SHA}.zip

# Get the UTC date in YYYYMMDD format
YYYYMMDD=$(date --date='TZ="UTC"' +'%Y%m%d')
export CHANGELOG_DATE=$(date --date='TZ="UTC"' +'%a %b %-d %Y')

export SNAPSHOT_NAME="${YYYYMMDD}git${LATEST_GIT_SHA_SHORT}"

# TODO(kwk): How to integrate the SNAPSHOT_NAME into the RELEASE below?
export RELEASE="%{?rc_ver:0.}%{baserelease}%{?rc_ver:.rc%{rc_ver}}.${SNAPSHOT_NAME}%{?dist}"

# Get LLVM version from CMakeLists.txt
wget -O tmp/CMakeLists.txt https://raw.githubusercontent.com/llvm/llvm-project/${LATEST_GIT_SHA}/llvm/CMakeLists.txt
export LLVM_VERSION_MAJOR=$(grep --regexp="set(\s*LLVM_VERSION_MAJOR" tmp/CMakeLists.txt | tr -d -c '[0-9]')
export LLVM_VERSION_MINOR=$(grep --regexp="set(\s*LLVM_VERSION_MINOR" tmp/CMakeLists.txt | tr -d -c '[0-9]')
export LLVM_VERSION_PATCH=$(grep --regexp="set(\s*LLVM_VERSION_PATCH" tmp/CMakeLists.txt | tr -d -c '[0-9]')
export LLVM_VERSION="${LLVM_VERSION_MAJOR}.${LLVM_VERSION_MINOR}.${LLVM_VERSION_PATCH}"

envsubst '${LATEST_GIT_SHA} ${LLVM_VERSION_MAJOR} ${LLVM_VERSION_MINOR} ${LLVM_VERSION_PATCH} ${LLVM_ARCHIVE_URL} ${RELEASE} ${CHANGELOG_DATE} ${SNAPSHOT_NAME}' < ./llvm.spec > llvm.spec.out

# Ensure %{_sourcdir} points to a writable location
mkdir -p /opt/notnfs/$USER/rpmbuild/SOURCES
echo '%_topdir /opt/notnfs/$USER/rpmbuild' >> ~/.rpmmacros
# The following should show /opt/notnfs/$USER/rpmbuild/SOURCES
# rpm --eval '%{_sourcedir}'

# Download files from the specfile into the current directory
spectool -R -g -A -C . llvm.spec.out

# Remove temporary files when done but only once, which is why we test before deletion.
function cleanup(){
    test -f "${LATEST_GIT_SHA}.zip" && rm -v ${LATEST_GIT_SHA}.zip
    test -f tmp/CMakeLists.txt && rm -v tmp/CMakeLists.txt
} 
trap 'cleanup'  SIGINT SIGTERM ERR EXIT

# Build SRPM
time mock -r rawhide.cfg --spec=llvm.spec.out --sources=$PWD --buildsrpm --resultdir=$PWD/tmp/rpms/ --no-cleanup-after --isolation=simple

# Build RPM
FCVER=$(grep -F "config_opts['releasever'] = " /etc/mock/templates/fedora-rawhide.tpl | tr -d -c '0-9')
time mock -r rawhide.cfg --spec=llvm.spec.out --rebuild $PWD/tmp/rpms/llvm-${LLVM_VERSION}-0.${SNAPSHOT_NAME}.fc${FCVER}.src.rpm --resultdir=$PWD/tmp/rpms/ --no-cleanup-after --isolation=simple
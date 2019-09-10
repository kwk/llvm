set -ex

# This test is meant to ensure that the cmake files in llvm-devel work
# when only the packages it depends on are installed.

ARCH=`rpm --eval '%_arch'`

llvm_devel_num_deps=`dnf repoquery --nvr --requires --resolve llvm-devel.$ARCH | grep '^llvm' | wc -l`

llvm_num_sub_packages_installed=`dnf list installed | grep  '^llvm' | wc -l`

# Verify that only llvm-devel dependencies are installed.
test `expr $llvm_devel_num_deps + 1` -eq $llvm_num_sub_packages_installed

# Verify that cmake files can me used without errors.
cmake -G Ninja .

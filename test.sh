#!/bin/bash
#
# Tests based on LLVM FileCheck.
#

num_succ=0
num_fail=0

check_ret_val_emit_status() {
if [ $? -ne 0 ]; then
  echo -e "[\e[31mFailed\e[0m]" " $file"!
  num_fail=$(($num_fail + 1))
else
  echo -e "[\e[32mPassed\e[0m]"
  num_succ=$(($num_succ + 1))
fi
}

# Tests with pet with tiling and parallelization disabled
TESTS="\
  test/matmul.c \
  test/heat-2d.c \
  test/heat-3d.c \
  test/jacobi-3d-25pt.c \
  "
for file in $TESTS; do
  printf '%-50s ' $file
  ./src/pluto $file --pet --notile --noparallel  -o test_temp_out.pluto.c | FileCheck $file
  check_ret_val_emit_status
done

# Tests with pet.
for file in $TESTS; do
    printf '%-50s ' "$file with --tile --parallel"
    ./src/pluto $file --pet -o test_temp_out.pluto.c | FileCheck --check-prefix TILE-PARALLEL $file
    check_ret_val_emit_status
done


TESTS="\
  test/matmul.c \
  test/jacobi-1d-imper.c \
  test/jacobi-2d-imper.c \
  test/matmul.c \
  test/costfunc.c \
  test/fdtd-2d.c \
  test/gemver.c \
  test/mvt.c \
  test/mxv.c \
  test/mxv-seq.c \
  test/mxv-seq3.c \
  test/matmul-seq.c \
  test/doitgen.c \
  test/polynomial.c \
  test/1dloop-invar.c \
  test/fusion1.c \
  test/fusion2.c \
  test/fusion3.c \
  test/fusion4.c \
  test/fusion5.c \
  test/fusion6.c \
  test/fusion7.c \
  test/fusion8.c \
  test/fusion9.c \
  test/fusion10.c \
  test/negparam.c \
  test/nodep.c \
  test/noloop.c \
  test/seidel.c \
  test/seq.c \
  test/shift.c \
  test/simple.c \
  test/tricky1.c \
  test/tricky2.c \
  test/tricky3.c \
  test/tricky4.c \
  test/wavefront.c \
  "
# Tests without --pet and without any tiling and parallelization "
for file in $TESTS; do
    printf '%-50s ' $file
    ./src/pluto --notile --noparallel $file $* -o test_temp_out.pluto.c | FileCheck $file
    check_ret_val_emit_status
done

# Pluto+ specific tests (without --pet and without any tiling/parallelization)"
echo -e "\nTest Pluto+ negative coeff's"
echo "==============================="
TESTS="\
  test/pluto+/dep-1,1.c \
  test/pluto+/rev+fusion.c \
  "
for file in $TESTS; do
    printf '%-50s ' $file
    ./src/pluto --notile --noparallel $file $* -o test_temp_out.pluto.c | FileCheck $file
    check_ret_val_emit_status
done

# These tests fail with the default islsolve but pass with GLPK or PIP.
# Pluto+ specific tests (without --pet and without any tiling/parallelization)"
echo -e "\nTests with PIP solve"
echo "========================="
TESTS="\
  test/matmul-seq3.c
  test/tce-4index-transform.c \
  "
for file in $TESTS; do
    printf '%-50s ' $file
    ./src/pluto --pipsolve --notile --noparallel $file $* -o test_temp_out.pluto.c | FileCheck $file
    check_ret_val_emit_status
done

# Test with ISS
echo -e "\nTest ISS"
echo "========"
TESTS_ISS="\
  test/jacobi-2d-periodic.c \
  test/multi-stmt-periodic.c \
  "
for file in $TESTS_ISS; do
    printf '%-50s ' $file
    ./src/pluto --pet --iss --notile --noparallel $file $* -o test_temp_out.pluto.c | FileCheck $file
    check_ret_val_emit_status
done

# Test with ISS + GLPK
# auto-transforms takes nearly 34s with islsolve on this, but just about 0.3s with GLPK.
echo -e "\nTest ISS with GLPK"
echo "======================="
TESTS_ISS="\
  test/multi-stmt-2d-periodic.c \
  "
for file in $TESTS_ISS; do
    printf '%-50s ' $file
    ./src/pluto --pet --glpk --iss --notile --noparallel $file $* -o test_temp_out.pluto.c | FileCheck $file
    check_ret_val_emit_status
done



# Test libpluto (disabling due to issue #48)
# printf '%-50s ' test_libpluto
# ./test_libpluto | FileCheck test/test_libpluto.c
# check_ret_val_emit_status

# Unit tests
printf '%-50s ' unit_tests
# Filter out all "// " comments from unit_tests.in when sending input to
# 'unit_tests'.
cat test/unit_tests.in | grep -v "^// " | ./unit_tests | FileCheck test/unit_tests.in
check_ret_val_emit_status


# TODO: add tests that check the generated code for certain things (like stmt
# body source esp. while using --pet).

cleanup()
{
rm -f test_temp_out.pluto.c
rm -f test_temp_out.pluto.pluto.cloog
}

echo ===========================
echo -e "$num_succ / $(($num_succ + $num_fail)) tests \e[32mPASSED\e[0m"
echo ===========================

trap cleanup SIGINT exit

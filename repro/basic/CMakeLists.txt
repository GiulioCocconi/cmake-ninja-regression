cmake_minimum_required(VERSION 3.31)
project(CompilerDetectionRepro LANGUAGES C CXX)
include(CheckCSourceCompiles)
check_c_source_compiles("int main(void) { return 0; }" COMPILER_TEST_OK)

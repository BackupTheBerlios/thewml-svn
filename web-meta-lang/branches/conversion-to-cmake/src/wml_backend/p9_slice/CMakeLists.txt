SET(CMAKE_VERBOSE_MAKEFILE ON)
include("../../Common.cmake")

PREPROCESS_PATH_PERL("slice_main.pl" "slice")
RUN_POD2MAN("slice.pod" "slice.1" "1" "EN Tools" "EN Tools")
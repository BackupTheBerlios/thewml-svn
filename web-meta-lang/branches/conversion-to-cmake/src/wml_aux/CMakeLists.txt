# see - http://www.cmake.org/Wiki/CMake_FAQ#Is_there_an_option_to_produce_more_.27verbose.27_compiling.3F
SET(CMAKE_VERBOSE_MAKEFILE ON)

CMAKE_MINIMUM_REQUIRED(VERSION 2.6)

SUBDIRS ( 
    iselect
    htmlclean
    htmlinfo
    linklint
    map2html
    tidy
    txt2html
    weblint
    freetable
    )

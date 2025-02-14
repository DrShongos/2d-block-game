project(uthash)

file(GLOB_RECURSE SOURCES uthash/src/*.c uthash/src/*.h)
add_library(uthash ${SOURCES})
set_target_properties(uthash PROPERTIES LINKER_LANGUAGE CXX)
target_include_directories(uthash PUBLIC uthash/src)

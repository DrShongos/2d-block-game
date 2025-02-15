project(FastNoiseLite)

add_library(FastNoiseLite FastNoiseLite/C/FastNoiseLite.h)
set_target_properties(FastNoiseLite PROPERTIES LINKER_LANGUAGE CXX)
target_include_directories(FastNoiseLite PUBLIC FastNoiseLite/C)

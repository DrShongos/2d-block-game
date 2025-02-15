#pragma once

#include "FastNoiseLite.h"
#include "chunk.h"
#include <stdint.h>

typedef struct {
   int64_t seed;
   fnl_state noise;

} world_generator;

void worldgen_init(world_generator *worldgen, int64_t seed);

world_chunk *worldgen_build_chunk(world_generator *worldgen, world_chunk *chunk);

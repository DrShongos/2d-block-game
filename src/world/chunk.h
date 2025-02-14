#pragma once

#include "raylib.h"
#include <stdint.h>
#define CHUNK_SIZE 16

typedef enum {
   BLOCK_AIR,
   BLOCK_DIRT,
   BLOCK_GRASS,
   BLOCK_UNKNOWN = 1024,
} chunk_block_type;

typedef struct {
    int64_t x;
    int64_t y;
} world_chunk_pos;

typedef struct {
    world_chunk_pos world_pos;
    chunk_block_type blocks[CHUNK_SIZE][CHUNK_SIZE];
} world_chunk;

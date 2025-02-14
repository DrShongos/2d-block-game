#pragma once
#include <raylib.h>
#include <utarray.h>
#include "../world/chunk.h"

#define TILE_SIZE 16.0f

typedef struct {
    Texture2D atlas;
    UT_array *tiles;
} tileset;

typedef enum {
    TILESET_CREATE_OK,
    TILESET_IMAGE_NOT_FOUND,
} tileset_create_result;

tileset_create_result tileset_create(tileset *new_tileset, const char *asset_path);
void tileset_delete(tileset *to_delete);

void tileset_draw_tile(tileset *set, chunk_block_type block, int64_t x, int64_t y);
void tileset_draw_chunk(tileset *ts, world_chunk *chunk);

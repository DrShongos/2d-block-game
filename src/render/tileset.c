#include "tileset.h"
#include "raylib.h"
#include "raymath.h"
#include "utarray.h"
#include <string.h>

// Structure necessary for initialization of the tile definition array.
static UT_icd tile_icd = {sizeof(Rectangle), NULL, NULL, NULL};

tileset_create_result tileset_create(tileset *new_tileset, const char *asset_path)
{
    Image atlas_image = LoadImage(asset_path);
    if (atlas_image.data == NULL)
        return TILESET_IMAGE_NOT_FOUND;

    new_tileset->atlas = LoadTextureFromImage(atlas_image);
    utarray_new(new_tileset->tiles, &tile_icd);

    float tile_x = 0.0f;
    float tile_y = 0.0f;

    for (int i = 0; i < BLOCK_UNKNOWN; i += 1) {
        if (i % 64 == 0 && i != 0) {
            tile_x = 0.0f;
            tile_y += TILE_SIZE;
        }

        Rectangle tile = {
            .x = tile_x,
            .y = tile_y,
            .width = TILE_SIZE,
            .height = TILE_SIZE,
        };
        utarray_push_back(new_tileset->tiles, &tile);
        tile_x += TILE_SIZE;
    }

    UnloadImage(atlas_image);

    return TILESET_CREATE_OK;
}

void tileset_delete(tileset *to_delete)
{
    UnloadTexture(to_delete->atlas);
    utarray_free(to_delete->tiles);
}

void tileset_draw_tile(tileset *ts, chunk_block_type block, int64_t x, int64_t y)
{
    if (block == BLOCK_AIR)
        return;

    Rectangle render_info = {
        .x = (float)x * TILE_SIZE,
        .y = (float)y * TILE_SIZE,
        .width = TILE_SIZE,
        .height = TILE_SIZE,
    };

    Rectangle *tile_src = utarray_eltptr(ts->tiles, block);

    DrawTexturePro(ts->atlas, *(tile_src), render_info, Vector2Zero(), 0.0, RAYWHITE);
}

void tileset_draw_chunk(tileset *ts, world_chunk *chunk)
{
    for (int64_t y = 0; y < CHUNK_SIZE; y += 1)
        for (int64_t x = 0; x < CHUNK_SIZE; x += 1)
            tileset_draw_tile(
                ts,
                chunk->blocks[y][x],
                x + (chunk->world_pos.x * CHUNK_SIZE),
                y + (chunk->world_pos.y * CHUNK_SIZE)
            );
}

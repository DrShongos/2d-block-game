#pragma once

#include "chunk.h"
#include "raylib.h"
#include "uthash.h"

#include "../render/tileset.h"
#include "../player.h"
#include "worldgen.h"

#define CHUNK_WORLD_SIZE (float)((float)CHUNK_SIZE * TILE_SIZE)
#define CHUNK_LOAD_RADIUS 10
#define CHUNK_MAX_PLR_DST (float)CHUNK_LOAD_RADIUS * CHUNK_WORLD_SIZE

typedef struct {
    world_chunk_pos pos;
    world_chunk chunk;

    /// The handle of the hash table.
    /// It should not be modified outside of macros contained in the uthash library.
    UT_hash_handle hh;
} world_chunk_record;

typedef struct {
    world_chunk_record *loaded_chunks;
    tileset main_tileset;

    world_generator worldgen;

    Camera2D main_camera;
    player main_player;
} world;

void world_create(world *new_world);
void world_delete(world *world);

/// Loads a new empty chunk into the loaded chunk table.
/// Returns a pointer to the new chunk.
/// If the chunk on that position already exists, it gets returned instead.
world_chunk *world_request_new_chunk(world *world, world_chunk_pos target_pos);

/// Requests a new chunk and fills it with blocks
/// Returns a pointer to the new chunk.
world_chunk *world_gen_chunk(world *world, world_chunk_pos pos);

/// Searches for a chunk within all loaded chunks that matches the specified position.
/// Returns the chunk if it exists, or `NULL` if it doesn't.
world_chunk *world_get_chunk(world *world, world_chunk_pos pos);
void world_delete_chunk(world *world, world_chunk_pos pos);

void world_draw_chunks(world *world);

/// Renders chunks and entities.
void world_draw(world* world);

/// Populates the world with new chunks around the player.
void world_gen_chunks(world* world);

void world_update(world* world);

world_chunk_pos pos_to_chunk_pos(Vector2 pos);

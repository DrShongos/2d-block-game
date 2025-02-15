#include "world.h"
#include "chunk.h"
#include "../player.h"
#include "raylib.h"
#include "raymath.h"
#include "uthash.h"
#include "worldgen.h"
#include <math.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>

void world_create(world *new_world)
{
    new_world->loaded_chunks = NULL;
    if (tileset_create(&new_world->main_tileset, "assets/tileset.png") != TILESET_CREATE_OK) {
       TraceLog(LOG_ERROR, "TILESET FILE COULD NOT BE FOUND.");
       CloseWindow();
       return;
    };

    Camera2D main_camera = {
        .offset = Vector2Zero(),
        .target = Vector2Zero(),
        .zoom = 1.0f,
    };

    new_world->main_camera = main_camera;
    new_world->main_player = player_new(Vector2Zero());

    srand(time(NULL));

    worldgen_init(&new_world->worldgen, rand());
    world_gen_chunks(new_world);
}

void world_delete(world *world)
{
    world_chunk_record *current_record, *tmp;

    HASH_ITER(hh, world->loaded_chunks, current_record, tmp) {
        HASH_DEL(world->loaded_chunks, current_record);
        free(current_record);
    }

    tileset_delete(&world->main_tileset);
}

static world_chunk_record *world_get_chunk_record(world *world, world_chunk_pos pos)
{
    world_chunk_record query, *found_record;

    // The padding within the structure has to be set 0 in order for
    // the searching to work properly.
    memset(&query, 0, sizeof(world_chunk_record));
    query.pos.x = pos.x;
    query.pos.y = pos.y;

    HASH_FIND(hh, world->loaded_chunks, &query.pos, sizeof(world_chunk_pos), found_record);

    return found_record;
}

world_chunk *world_request_new_chunk(world *world, world_chunk_pos target_pos)
{
    // Ensure there's no chunk that exists on that position already
    world_chunk_record *new_record, *existing_record;
    existing_record = world_get_chunk_record(world, target_pos);
    if (existing_record != NULL)
       return &existing_record->chunk;

    new_record = (world_chunk_record *)malloc(sizeof *new_record);

    // The padding must be set to zero.
    memset(new_record, 0, sizeof *new_record);

    new_record->pos = target_pos;
    new_record->chunk.world_pos = target_pos;
    HASH_ADD(hh, world->loaded_chunks, pos, sizeof(world_chunk_pos), new_record);

    return &new_record->chunk;
}

world_chunk *world_gen_chunk(world *world, world_chunk_pos pos)
{
    world_chunk *new_chunk = world_request_new_chunk(world, pos);
    worldgen_build_chunk(&world->worldgen, new_chunk);

    return new_chunk;
}

world_chunk *world_get_chunk(world *world, world_chunk_pos pos)
{
    world_chunk_record *found_record = world_get_chunk_record(world, pos);

    if (found_record == NULL)
        return NULL;

    return &found_record->chunk;
}

void world_delete_chunk(world *world, world_chunk_pos pos)
{
    world_chunk_record *chunk_record = world_get_chunk_record(world, pos);
    if (chunk_record == NULL)
        return;

    HASH_DEL(world->loaded_chunks, chunk_record);
    free(chunk_record);
}

static bool chunk_within_view(world_chunk_pos chunk_pos, Camera2D* camera)
{
   // Chunk positions have to be manually offset by the camera's offset.
   // It's to make sure that the chunk fits the actual view.
   float chunk_x = ((float)chunk_pos.x * CHUNK_WORLD_SIZE) + (camera->offset.x / camera->zoom);
   float chunk_y = ((float)chunk_pos.y * CHUNK_WORLD_SIZE) + (camera->offset.y / camera->zoom);

   Rectangle camera_bounds = {
       camera->target.x,
       camera->target.y,
       (float)GetScreenWidth() / camera->zoom,
       (float)GetScreenHeight() / camera->zoom,
   };

   return (
      chunk_x < camera_bounds.x + camera_bounds.width &&
      chunk_x + CHUNK_WORLD_SIZE > camera_bounds.x &&
      chunk_y < camera_bounds.y + camera_bounds.height &&
      chunk_y + CHUNK_WORLD_SIZE > camera_bounds.y
   );
}

void world_draw_chunks(world *world)
{
    world_chunk_record *current_record;

    for (current_record = world->loaded_chunks; current_record != NULL; current_record = current_record->hh.next) {
        if (chunk_within_view(current_record->pos, &world->main_camera))
            tileset_draw_chunk(&world->main_tileset, &current_record->chunk);
    }
}

void world_draw(world* world)
{
    BeginMode2D(world->main_camera);

    world_draw_chunks(world);
    player_draw(&world->main_player);

    EndMode2D();
}

void world_gen_chunks(world *world)
{
    world_chunk_pos player_pos = pos_to_chunk_pos(world->main_player.position);

    int64_t generation_y_min = player_pos.y - CHUNK_LOAD_RADIUS;
    int64_t generation_y_max = player_pos.y + CHUNK_LOAD_RADIUS;

    int64_t generation_x_min = player_pos.x - CHUNK_LOAD_RADIUS;
    int64_t generation_x_max = player_pos.x + CHUNK_LOAD_RADIUS;

    for (int64_t y = generation_y_min; y <= generation_y_max; y += 1)
        for (int64_t x = generation_x_min; x < generation_x_max; x += 1) {
            world_chunk_pos pos = {x, y};

            float plr_distance = player_distance_from_chunk(pos, world->main_player.position);
            if (world_get_chunk(world, pos) == NULL && plr_distance < CHUNK_MAX_PLR_DST) {
                //TraceLog(LOG_INFO, "no chunk at position %d %d, generating...", x, y);
                world_gen_chunk(world, pos);
            }
        }
}

// TODO: Move to a separate file later maybe??
static void camera_update(world* world)
{
    world->main_camera.target = world->main_player.position;

    float mouse_wheel = GetMouseWheelMove();
    float scroll_val = 0.0f;

    if (mouse_wheel >= 0.1f) {
        scroll_val = 0.1f;
    } else if (mouse_wheel < 0.0f) {
        scroll_val = -0.1f;
    }
    world->main_camera.zoom += scroll_val;
    world->main_camera.zoom = Clamp(world->main_camera.zoom, CAMERA_MIN_ZOOM, CAMERA_MAX_ZOOM);
}

void world_update(world* world)
{
    player_update(&world->main_player);
    camera_update(world);

    // Handle chunk updates and loading
    world_chunk_record *current_record, *tmp;
    bool chunk_regen_needed = false;

    HASH_ITER(hh, world->loaded_chunks, current_record, tmp) {
        float chunk_dst = player_distance_from_chunk(current_record->pos, world->main_player.position);

        if (chunk_dst >= CHUNK_MAX_PLR_DST) {
            world_delete_chunk(world, current_record->pos);
            chunk_regen_needed = true;
        }
    }

    if (chunk_regen_needed)
        world_gen_chunks(world);


    // Center the camera
    Vector2 cam_offset = {GetScreenWidth() / 2.0f, GetScreenHeight() / 2.0f};
    world->main_camera.offset = cam_offset;
}

world_chunk_pos pos_to_chunk_pos(Vector2 pos)
{
    int64_t chunk_x = (floorf(pos.x / (float)CHUNK_WORLD_SIZE));
    int64_t chunk_y = (floorf(pos.y / (float)CHUNK_WORLD_SIZE));

    world_chunk_pos chunk_pos = {
        .x = chunk_x,
        .y = chunk_y,
    };
    return chunk_pos;
}

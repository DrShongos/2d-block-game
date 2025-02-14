#include "player.h"
#include "raylib.h"
#include "raymath.h"
#include "world/chunk.h"
#include "world/world.h"
#include <math.h>

player player_new(Vector2 start_pos)
{
   player new_player = {
      .position = start_pos,
      .velocity = Vector2Zero(),
      .bounds = {16.0f, 16.0f},
      .speed = 64.0f,
   };

   return new_player;
}

void player_draw(player* plr)
{
    DrawRectangleV(plr->position, plr->bounds, BLUE);
}

void player_update(player* plr)
{
    plr->velocity.x = (float)(IsKeyDown(KEY_D)) - (float)(IsKeyDown(KEY_A));
    plr->velocity.y = (float)(IsKeyDown(KEY_S)) - (float)(IsKeyDown(KEY_W));

    plr->position = Vector2Add(
        plr->position,
        Vector2Scale(plr->velocity, plr->speed * GetFrameTime())
    );
}

float player_distance_from_chunk(world_chunk_pos chunk_pos, Vector2 player_pos)
{
    float chunk_x = (float)chunk_pos.x * CHUNK_WORLD_SIZE;
    float chunk_y = (float)chunk_pos.y * CHUNK_WORLD_SIZE;

    return sqrtf(powf(player_pos.x - chunk_x, 2) + powf(player_pos.y - chunk_y, 2));
}

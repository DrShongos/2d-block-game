#pragma once

#include "raylib.h"
#include "world/chunk.h"

typedef struct {
   Vector2 position;
   Vector2 velocity;
   Vector2 bounds;
   float speed;
} player;

player player_new(Vector2 start_pos);

void player_draw(player* plr);
void player_update(player* plr);

float player_distance_from_chunk(world_chunk_pos chunk_pos, Vector2 player_pos);

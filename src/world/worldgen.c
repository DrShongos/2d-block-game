#include "worldgen.h"
#include "FastNoiseLite.h"
#include "chunk.h"

void worldgen_init(world_generator *worldgen, int64_t seed)
{
    worldgen->seed = seed;
    worldgen->noise = fnlCreateState();
    worldgen->noise.noise_type = FNL_NOISE_PERLIN;
    worldgen->noise.seed = seed;

    worldgen->noise.frequency = 0.005;
}

world_chunk *worldgen_build_chunk(world_generator *worldgen, world_chunk *chunk)
{
    for (int y = 0; y < CHUNK_SIZE; y += 1)
        for (int x = 0; x < CHUNK_SIZE; x += 1) {
            float noise_result = fnlGetNoise2D(
                &worldgen->noise,
                (FNLfloat)((chunk->world_pos.x * CHUNK_SIZE) + x) * 16.0f,
                (FNLfloat)((chunk->world_pos.y * CHUNK_SIZE) + y) * 16.0f
            );

            if (noise_result >= 0.2f)
                chunk->blocks[y][x] = BLOCK_DIRT;
            else if (noise_result >= 0.1f && noise_result < 0.2f)
                chunk->blocks[y][x] = BLOCK_GRASS;
            else
                chunk->blocks[y][x] = BLOCK_AIR;
        }

    return chunk;
}

float worldgen_get_terrain_y(world_generator* worldgen, float block_x);

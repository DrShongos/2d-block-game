#include "worldgen.h"
#include "FastNoiseLite.h"
#include "chunk.h"
#include "raymath.h"
#include <math.h>
#include <stdlib.h>

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
    for (int x = 0; x < CHUNK_SIZE; x += 1) {
        float noise_result = fnlGetNoise2D(
            &worldgen->noise,
            (FNLfloat)((chunk->world_pos.x * CHUNK_SIZE) + x) * 4.0f,
            0.0f
        );

        float terrain_y = noise_result * CHUNK_SIZE * 4.0f;

        int64_t ground_height = roundf(terrain_y - (float)(chunk->world_pos.y * CHUNK_SIZE));

        // Ensure that the resulting ground height never exceeds chunk bounds.
        if (ground_height >= 0 && ground_height < CHUNK_SIZE) {
            // REMEMBER: A chunk's Y goes from top to bottom.
            // As such, to fill a chunk below a certain height it needs to increment above the height.
            for (int y = ground_height; y < CHUNK_SIZE; y += 1) {
                chunk->blocks[y][x] = BLOCK_DIRT;
            }

            chunk->blocks[ground_height][x] = BLOCK_GRASS;
        }

        if (ground_height < 0) {
            for (int y = 0; y < CHUNK_SIZE; y += 1)
                chunk->blocks[y][x] = BLOCK_DIRT;
        }

    };

    return chunk;
}

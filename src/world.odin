package main

import "core:math/rand"
import "core:time"
import rl "vendor:raylib"

CHUNK_SIZE :: 16
CHUNK_BOUNDING_DIM: f32 : (CHUNK_SIZE * TILE_SIZE)

Tile :: enum {
    Air,
    Dirt,
    Grass,
    Unknown = 1024,
}

Chunk_Pos :: struct {
    x: i64,
    y: i64,
}

Chunk :: struct {
    pos:   Chunk_Pos,
    tiles: [CHUNK_SIZE][CHUNK_SIZE]Tile,
}

// Checks whether the chunk is visible on the camera.
// It is calculated with the AABB collision detection algorithm.
chunk_is_within_view :: proc(pos: Chunk_Pos, camera: ^World_Camera) -> bool {
    // Chunk positions need to be offset manually by the camera's offset.
    // I have no idea why it has to be done.
    chunk_x :=
        f32(pos.x * CHUNK_SIZE * TILE_SIZE) +
        (camera.camera.offset.x / camera.camera.zoom)
    chunk_y :=
        f32(pos.y * CHUNK_SIZE * TILE_SIZE) +
        (camera.camera.offset.y / camera.camera.zoom)

    camera_bounds := camera_get_view_bounds(camera)

    return(
        chunk_x < camera_bounds.x + camera_bounds.width &&
        chunk_x + CHUNK_BOUNDING_DIM > camera_bounds.x &&
        chunk_y < camera_bounds.x + camera_bounds.height &&
        chunk_y + CHUNK_BOUNDING_DIM > camera_bounds.y \
    )
}

chunk_draw :: proc(chunk: ^Chunk, world: ^World) {
    for row, y in chunk.tiles {
        for tile, x in row {
            tileset_draw_tile(
                &world.tileset,
                tile,
                (chunk.pos.x * CHUNK_SIZE) + i64(x),
                (chunk.pos.y * CHUNK_SIZE) + i64(y),
            )
        }
    }
}


World :: struct {
    loaded_chunks: map[Chunk_Pos]Chunk,
    tileset:       Tileset,
    player:        Player,
    camera:        World_Camera,
}

world_new :: proc() -> World {
    loaded_chunks := map[Chunk_Pos]Chunk{}

    rng := rand.create(transmute(u64)time.time_to_unix_nano(time.now()))
    context.random_generator = rand.default_random_generator(&rng)

    // Generate a finite world filled with random blocks
    for y in -20 ..= 20 {
        for x in -20 ..= 20 {
            new_chunk := Chunk{}
            new_chunk.pos = {i64(x), i64(y)}

            for local_y in 0 ..< CHUNK_SIZE {
                for local_x in 0 ..< CHUNK_SIZE {
                    block_id := rand.uint64() % (u64(Tile.Grass) + 1)

                    new_chunk.tiles[local_y][local_x] = Tile(block_id)
                }
            }

            map_insert(&loaded_chunks, Chunk_Pos{i64(x), i64(y)}, new_chunk)
        }
    }

    return World {
        loaded_chunks = loaded_chunks,
        tileset = tileset_new("assets/tileset.png"),
        player = create_player(),
        camera = camera_new(),
    }
}

world_update :: proc(world: ^World) {
    dt := rl.GetFrameTime()

    camera_update(&world.camera, world)
    player_update(&world.player, dt)
}

world_draw :: proc(world: ^World) {
    rl.BeginMode2D(world.camera.camera)

    for chunk_pos, &chunk in world.loaded_chunks {
        if chunk_is_within_view(chunk_pos, &world.camera) {
            chunk_draw(&chunk, world)
        }
    }
    player_draw(&world.player)

    rl.EndMode2D()
}

world_delete :: proc(world: ^World) {
    delete_map(world.loaded_chunks)
    tileset_delete(&world.tileset)
}

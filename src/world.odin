package main

import "core:math/rand"
import "core:time"
import rl "vendor:raylib"

CHUNK_SIZE :: 16

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
    camera:        rl.Camera2D,
}

world_new :: proc() -> World {
    loaded_chunks := map[Chunk_Pos]Chunk{}

    rng := rand.create(transmute(u64)time.time_to_unix_nano(time.now()))
    context.random_generator = rand.default_random_generator(&rng)

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
        camera = rl.Camera2D {
            offset = {1280.0 / 2.0, 720.0 / 2.0},
            rotation = 0.0,
            zoom = 1.0,
            target = {0.0, 0.0},
        },
    }
}

world_update :: proc(world: ^World) {
    dt := rl.GetFrameTime()

    world.camera.target = {world.player.position.x, world.player.position.y}
    player_update(&world.player, dt)
}

world_draw :: proc(world: ^World) {
    rl.BeginMode2D(world.camera)

    for chunk_pos, &chunk in world.loaded_chunks {
        chunk_draw(&chunk, world)
    }
    player_draw(&world.player)

    rl.EndMode2D()
}

world_delete :: proc(world: ^World) {
    delete_map(world.loaded_chunks)
}

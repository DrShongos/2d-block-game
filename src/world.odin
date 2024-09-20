package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:time"
import rl "vendor:raylib"

CHUNK_SIZE :: 16
CHUNK_WORLD_SIZE: f32 : (CHUNK_SIZE * TILE_SIZE)

CHUNK_LOADING_RADIUS :: 10

CHUNK_MAX_DST_FROM_PLAYER: f32 : f32(CHUNK_LOADING_RADIUS) * CHUNK_WORLD_SIZE

Chunk_Storage :: map[Chunk_Pos]Chunk

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
        f32(pos.x) * CHUNK_WORLD_SIZE +
        (camera.camera.offset.x / camera.camera.zoom)
    chunk_y :=
        f32(pos.y) * CHUNK_WORLD_SIZE +
        (camera.camera.offset.y / camera.camera.zoom)

    camera_bounds := camera_get_view_bounds(camera)

    return(
        chunk_x < camera_bounds.x + camera_bounds.width &&
        chunk_x + CHUNK_WORLD_SIZE > camera_bounds.x &&
        chunk_y < camera_bounds.x + camera_bounds.height &&
        chunk_y + CHUNK_WORLD_SIZE > camera_bounds.y \
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

chunk_distance_from_player :: proc(
    chunk_pos: Chunk_Pos,
    player_pos: rl.Vector2,
) -> f32 {
    chunk_x := f32(chunk_pos.x) * CHUNK_WORLD_SIZE
    chunk_y := f32(chunk_pos.y) * CHUNK_WORLD_SIZE

    return math.sqrt(
        math.pow(player_pos.x - chunk_x, 2) +
        math.pow(player_pos.y - chunk_y, 2),
    )
}


World :: struct {
    loaded_chunks: Chunk_Storage,
    tileset:       Tileset,
    player:        Player,
    camera:        World_Camera,
}

world_new :: proc() -> World {
    loaded_chunks := Chunk_Storage{}

    rng := rand.create(transmute(u64)time.time_to_unix_nano(time.now()))
    context.random_generator = rand.default_random_generator(&rng)

    // Generate a finite world filled with random blocks
    for y in -CHUNK_LOADING_RADIUS ..< CHUNK_LOADING_RADIUS {
        dx := i64(
            math.floor(
                math.sqrt(
                    f32(CHUNK_LOADING_RADIUS * CHUNK_LOADING_RADIUS) -
                    f32(y * y),
                ),
            ),
        )
        for x in -dx ..< dx {
            world_gen_chunk(&loaded_chunks, {i64(x), i64(y)})
        }
    }

    return World {
        loaded_chunks = loaded_chunks,
        tileset = tileset_new("assets/tileset.png"),
        player = create_player(),
        camera = camera_new(),
    }
}

world_gen_chunk :: proc(chunk_storage: ^Chunk_Storage, pos: Chunk_Pos) {
    new_chunk := Chunk{}
    new_chunk.pos = pos

    for local_y in 0 ..< CHUNK_SIZE {
        for local_x in 0 ..< CHUNK_SIZE {
            block_id := rand.uint64() % (u64(Tile.Grass) + 1)

            new_chunk.tiles[local_y][local_x] = Tile(block_id)
        }
    }

    map_insert(chunk_storage, pos, new_chunk)
}

world_update :: proc(world: ^World) {
    dt := rl.GetFrameTime()

    camera_update(&world.camera, world)
    player_update(&world.player, dt)


    for chunk_pos, &chunk in world.loaded_chunks {
        chunk_dst := chunk_distance_from_player(
            chunk_pos,
            world.player.position,
        )
        if chunk_dst >= CHUNK_MAX_DST_FROM_PLAYER {
            delete_key(&world.loaded_chunks, chunk_pos)

            // Whenever a chunk gets deleted, the world will generate new chunks around the player
            world_reload_chunks(world)
        }
    }
}

world_reload_chunks :: proc(world: ^World) {
    player_chunk_pos := pos_to_chunk_pos(world.player.position)

    generation_radius_y_min := player_chunk_pos.y - CHUNK_LOADING_RADIUS
    generation_radius_y_max := player_chunk_pos.y + CHUNK_LOADING_RADIUS

    generation_radius_x_min := player_chunk_pos.x - CHUNK_LOADING_RADIUS
    generation_radius_x_max := player_chunk_pos.x + CHUNK_LOADING_RADIUS

    for y in generation_radius_y_min ..< generation_radius_y_max {
        for x in generation_radius_x_min ..< generation_radius_x_max {
            chunk_pos := Chunk_Pos{i64(x), i64(y)}
            chunk_already_exists := chunk_pos in world.loaded_chunks

            if !chunk_already_exists &&
               chunk_distance_from_player(chunk_pos, world.player.position) <
                   CHUNK_MAX_DST_FROM_PLAYER {
                world_gen_chunk(&world.loaded_chunks, chunk_pos)
            }
        }
    }
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

pos_to_chunk_pos :: proc(pos: rl.Vector2) -> Chunk_Pos {
    chunk_x := cast(i64)(pos.x / CHUNK_WORLD_SIZE)
    chunk_y := cast(i64)(pos.y / CHUNK_WORLD_SIZE)

    return Chunk_Pos{x = chunk_x, y = chunk_y}
}

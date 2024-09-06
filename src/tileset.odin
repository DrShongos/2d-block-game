package main

import rl "vendor:raylib"

TILE_SIZE :: 16.0

// A Texture atlas that contains every tile in the game.
// Textures are stored in order that matches the tile's ID.
Tileset :: struct {
    atlas:        rl.Texture2D,
    tile_indexes: [dynamic]rl.Rectangle,
}

tileset_new :: proc(path: cstring) -> Tileset {
    atlas_image := rl.LoadImage(path)
    defer rl.UnloadImage(atlas_image)

    atlas := rl.LoadTextureFromImage(atlas_image)

    tileset := Tileset{}

    tile_x: f32 = 0.0
    tile_y: f32 = 0.0

    for i in 0 ..< u32(Tile.Unknown) {
        if i % 64 == 0 && i != 0 {
            tile_x = 0.0
            tile_y += TILE_SIZE
        }

        tile := rl.Rectangle {
            x      = tile_x,
            y      = tile_y,
            width  = TILE_SIZE,
            height = TILE_SIZE,
        }

        append(&tileset.tile_indexes, tile)

        tile_x += TILE_SIZE
    }

    tileset.atlas = atlas

    return tileset
}

tileset_delete :: proc(tileset: ^Tileset) {
    rl.UnloadTexture(tileset.atlas)
    delete(tileset.tile_indexes)
}

// Draws the specified tile.
// The tile is sent to a sprite batch, that displays all of them at once.
tileset_draw_tile :: proc(tileset: ^Tileset, tile_type: Tile, x: i64, y: i64) {
    if tile_type != .Air {
        rendered_tile := rl.Rectangle {
            x      = f32(x) * TILE_SIZE,
            y      = f32(y) * TILE_SIZE,
            width  = TILE_SIZE,
            height = TILE_SIZE,
        }

        rl.DrawTexturePro(
            tileset.atlas,
            tileset.tile_indexes[u32(tile_type)],
            rendered_tile,
            {0.0, 0.0},
            0.0,
            rl.WHITE,
        )
    }
}

package main

import rl "vendor:raylib"

World_Camera :: struct {
    camera: rl.Camera2D,
    bounds: rl.Vector2,
}

camera_new :: proc() -> World_Camera {
    return World_Camera {
        camera = rl.Camera2D {
            target = {0.0, 0.0},
            offset = {
                f32(rl.GetScreenWidth()) / 2.0,
                f32(rl.GetScreenHeight()) / 2.0,
            },
            rotation = 0.0,
            zoom = 1.0,
        },
        bounds = {f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())},
    }
}

camera_update :: proc(camera: ^World_Camera, world: ^World) {
    camera.bounds = {
        f32(rl.GetScreenWidth()) / camera.camera.zoom,
        f32(rl.GetScreenHeight()) / camera.camera.zoom,
    }
    camera.camera.target = {world.player.position.x, world.player.position.y}
    camera.camera.offset = {
        f32(rl.GetScreenWidth()) / 2.0,
        f32(rl.GetScreenHeight()) / 2.0,
    }

    camera.camera.zoom += rl.GetMouseWheelMove() / 8.0
}

camera_get_view_bounds :: proc(camera: ^World_Camera) -> rl.Rectangle {
    return rl.Rectangle {
        x = camera.camera.target.x,
        y = camera.camera.target.y,
        width = camera.bounds.x,
        height = camera.bounds.y,
    }
}

Player :: struct {
    position: rl.Vector2,
    speed:    f32,
}

create_player :: proc() -> Player {
    return Player{position = {0.0, 0.0}, speed = 128.0}
}

player_update :: proc(player: ^Player, dt: f32) {
    if rl.IsKeyDown(.W) {
        player.position[1] -= 1.0 * player.speed * dt
    }

    if rl.IsKeyDown(.S) {
        player.position[1] += 1.0 * player.speed * dt
    }

    if rl.IsKeyDown(.A) {
        player.position[0] -= 1.0 * player.speed * dt
    }

    if rl.IsKeyDown(.D) {
        player.position[0] += 1.0 * player.speed * dt
    }
}

player_draw :: proc(player: ^Player) {
    rl.DrawRectangleV(player.position, {16.0, 16.0}, rl.RED)
}

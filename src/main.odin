package main

import fmt "core:fmt"

import rl "vendor:raylib"

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

main :: proc() {
    rl.InitWindow(1280, 720, "2D Block Game")
    defer rl.CloseWindow()

    world := world_new()
    defer world_delete(&world)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()

        world_update(&world)

        rl.BeginDrawing()
        rl.ClearBackground(rl.GRAY)

        world_draw(&world)

        rl.EndDrawing()
    }
}

package main

import fmt "core:fmt"

import rl "vendor:raylib"


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

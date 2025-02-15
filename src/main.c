#include <raylib.h>
#include <uthash.h>

#define FNL_IMPL
#include <FastNoiseLite.h>

#include "world/chunk.h"
#include "world/world.h"

int main()
{
    InitWindow(1280, 720, "Cloneria");

    world main_world;
    world_create(&main_world);

    while (!WindowShouldClose()) {
        world_update(&main_world);

        BeginDrawing();
        ClearBackground(GRAY);

        world_draw(&main_world);

        EndDrawing();
    }
    CloseWindow();

    world_delete(&main_world);
    return 0;
}

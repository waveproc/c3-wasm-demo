// c3c compile -D PLATFORM_WEB --reloc=none --target wasm32 -O3 -g0 --link-libc=no --no-entry -o demo -z --export-table flappybird.c3 raylib.c3
module flappybird;

import raylib;
alias Entry = fn void();
extern fn void raylib_js_set_entry(Entry entry) @wasm;

alias Vec2 = float[<2>];

const int WINDOW_WIDTH = 800;
const int WINDOW_HEIGHT = 600;
Vec2 gravity = {0, 2000};
float birdRadius = 20f;
Vec2 flapImpulse = {0, -1000};
Vec2 birdPos = {(float)WINDOW_WIDTH / 4.0f, (float)WINDOW_HEIGHT / 2.0f};
Vec2 birdVel = {0.0f, 0.0f};
bool wingUp = true;
float wingTimer = 0.0f;
float pipeX = (float)WINDOW_WIDTH;
float pipeGapY = (float)WINDOW_HEIGHT / 2.0f;
int gapHalf = 100;
int score = 0;
bool passedPipe = false;
float[] treeX = {150.0f, 350.0f, 550.0f, 750.0f};
Vec2[] clouds = {
    {100.0f, 100.0f},
    {400.0f, 80.0f},
    {700.0f, 120.0f}
};
float startTime;
float gameTime;

fn Vec2 min(Vec2 a, Vec2 b)
{
    Vec2 result;
    result.x = (a.x < b.x) ? a.x : b.x;
    result.y = (a.y < b.y) ? a.y : b.y;
    return result;
}

fn Vec2 max(Vec2 a, Vec2 b)
{
    Vec2 result;
    result.x = (a.x > b.x) ? a.x : b.x;
    result.y = (a.y > b.y) ? a.y : b.y;
    return result;
}

fn Vec2 clamp(Vec2 x, Vec2 upper, Vec2 lower)
{
    return min(upper, max(x, lower));
}

fn void draw_bird(Vec2 pos, bool wingUp) {
    // Body
    raylib::draw_circle_v({pos.x, pos.y}, (float)birdRadius, raylib::YELLOW);

    // // Beak
    // raylib::draw_triangle(
    //     {pos.x + (float)birdRadius, pos.y},
    //     {pos.x + (float)birdRadius + 10.0f, pos.y - 5.0f},
    //     {pos.x + (float)birdRadius + 10.0f, pos.y + 5.0f},
    //     raylib::ORANGE
    // );

    // Eye
    raylib::draw_circle_v({pos.x + (float)birdRadius / 3.0f, pos.y - (float)birdRadius / 3.0f}, 5.0f, raylib::WHITE);
    raylib::draw_circle_v({pos.x + (float)birdRadius / 3.0f, pos.y - (float)birdRadius / 3.0f}, 2.0f, raylib::BLACK);

    // // Wing
    // float wingAngle = wingUp ? -15.0f : 15.0f;
    // raylib::draw_triangle(
    //     {pos.x - 5.0f, pos.y},
    //     {pos.x - 25.0f, pos.y + wingAngle},
    //     {pos.x - 5.0f, pos.y + 10.0f},
    //     raylib::BROWN
    // );
}

fn void draw_pipe(float x, float gapY, int gapHalf) {
    // Pipe
    raylib::draw_rectangle((int)x, 0, 60, (int)(gapY - (float)gapHalf), raylib::GREEN);
    raylib::draw_rectangle((int)x, (int)(gapY + (float)gapHalf), 60, WINDOW_HEIGHT - (int)(gapY + (float)gapHalf) - 40, raylib::GREEN);

    // Pipe Cap
    raylib::draw_rectangle((int)x - 5, (int)(gapY - (float)gapHalf) - 20, 70, 20, raylib::DARKGREEN);
    raylib::draw_rectangle((int)x - 5, (int)(gapY + (float)gapHalf), 70, 20, raylib::DARKGREEN);
}

// fn void draw_ground_trees(float[] treeX) {
//     for (int i = 0; i < treeX.len; i++) {
//         float baseY = (float)WINDOW_HEIGHT - 40.0f;
//         raylib::draw_rectangle((int)treeX[i] - 5, (int)baseY - 30, 10, 30, raylib::BROWN);
//         raylib::draw_circle_v({(int)treeX[i], (float)((int)baseY - 40)}, 15.0f, raylib::DARKGREEN);
//     }
// }

fn void draw_clouds(Vec2[] clouds) {
    for (int i = 0; i < clouds.len; i++) {
        raylib::draw_circle_v({clouds[i].x, clouds[i].y}, 20.0f, raylib::LIGHTGRAY);
        raylib::draw_circle_v({clouds[i].x + 20.0f, clouds[i].y + 5.0f}, 18.0f, raylib::LIGHTGRAY);
        raylib::draw_circle_v({clouds[i].x - 20.0f, clouds[i].y + 5.0f}, 18.0f, raylib::LIGHTGRAY);
    }
}

fn void game_frame() @wasm {
    float dt = raylib::get_frame_time();
    gameTime += dt;

    // Input
    switch {
        case (raylib::is_key_pressed(raylib::KEY_SPACE) || raylib::is_key_pressed(raylib::KEY_UP)):
            birdVel += flapImpulse;
            birdVel = clamp(birdVel, (Vec2){0, -650}, (Vec2){0,0});
        // case (raylib::is_mouse_button_down(raylib::MouseButton.LEFT)):
        //     birdVel += flapImpulse / 14;
        //     birdVel = math::clamp(birdVel, (Vec2){0, -650}, (Vec2){0,0});
        // case (raylib::is_mouse_button_down(raylib::MouseButton.RIGHT) || raylib::is_key_pressed(raylib::KEY_DOWN)):
        //     birdVel -= flapImpulse / 14;
        //     birdVel = math::clamp(birdVel, (Vec2){0, +350}, (Vec2){0,0});
    }

    // Ultra Physics phxv2, so complicated 
    birdVel += gravity * dt;
    birdPos += birdVel * dt;

    // Wing animation toggle
    wingTimer += dt;
    if (wingTimer > 0.15f) {
        wingUp = !wingUp;
        wingTimer = 0.0f;
    }

    // Move Pipe
    pipeX -= 300.0f * dt + (float)(gameTime * 0.3);
    if (pipeX < -60.0f) {
        pipeX = (float)WINDOW_WIDTH;
        pipeGapY = (float)raylib::get_random_value(0, (WINDOW_HEIGHT - 200)) + 100.0f;
        passedPipe = false;
    }

    // Calculate Score
    if (!passedPipe && birdPos.x > pipeX + 60.0f) {
        score++;
        passedPipe = true;
    }

    // Cloud movement
    for (int i = 0; i < clouds.len; i++) {
        clouds[i].x -= 100.0f * dt; // slow drift
        if (clouds[i].x < -50.0f) {
            clouds[i].x = (float)WINDOW_WIDTH + 50.0f;
        }
    }

    // Tree movement
    foreach (&tree : treeX) {
        *tree -= 300.0f * dt;
        if (*tree < -10.0f) {
            *tree = (float)WINDOW_WIDTH + 10.0f;
        }
    }

    raylib::@drawing()
    {
        raylib::clear_background(raylib::SKYBLUE);

        draw_clouds(clouds);
        // draw_ground_trees(treeX);

        // Ground? sure
        raylib::draw_rectangle(0, WINDOW_HEIGHT - 40, WINDOW_WIDTH, 40, raylib::BROWN);

        draw_pipe(pipeX, pipeGapY, gapHalf);
        draw_bird(birdPos, wingUp);

        // Score
        // raylib::draw_text(string::tformat_zstr("Score: %d", score), 10, 10, 30, raylib::BLACK);
    };

    // Collision
    // Floor collision (bounce)
    if (birdPos.y + (float)birdRadius > (float)(WINDOW_HEIGHT - 40)) {
        birdPos.y = (float)(WINDOW_HEIGHT - 40) - (float)birdRadius;
        birdVel.y *= -0.6f; // Bounce with some energy loss
    }
    // Pipe collision (game over? restart)
    if (birdPos.x + (float)birdRadius > pipeX && birdPos.x - (float)birdRadius < pipeX + 60.0f
        && (birdPos.y - (float)birdRadius < pipeGapY - (float)gapHalf
            || birdPos.y + (float)birdRadius > pipeGapY + (float)gapHalf)) {
        // Reset
        birdPos = {(float)WINDOW_WIDTH / 4.0f, (float)WINDOW_HEIGHT / 2.0f};
        birdVel = {0.0f, 0.0f};
        pipeX = (float)WINDOW_WIDTH;
        score = 0;
        passedPipe = false;
        gameTime = 0;
        raylib::@drawing()
        {
            raylib::clear_background(raylib::RED);
        };
    }
}

fn void main() @extern("main") @wasm {
    raylib::init_window(WINDOW_WIDTH, WINDOW_HEIGHT, "Flappy Bird in C3 - Enhanced");
    raylib::set_target_fps(60);

    raylib_js_set_entry(&game_frame);
    while (!raylib::window_should_close()) {
        game_frame();
    }

    raylib::close_window();
}

// This flappybird game was created by ManuLinares:
// https://github.com/ManuLinares/flappybird-c3/blob/master/src/main.c3

// c3c compile -D PLATFORM_WEB --reloc=none --target wasm32 -O3 -g0 --no-entry -o demo -z --export-table flappybird.c3 rl.c3
import rl;
// import std::io;

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
    {700.0f, 120.0f},
};
float startTime;
float gameTime;

// Polyfill for missing libc function
fn usz strlen(char* str) @extern("strlen") @wasm {
    usz len = 0;
    while (str[len] != 0) len++;
    return len;
}

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
    rl::draw_circle_v({pos.x, pos.y}, (float)birdRadius, rl::YELLOW);

    // Beak
    rl::draw_triangle(
        {pos.x + (float)birdRadius, pos.y - 5.0f},
        {pos.x + (float)birdRadius, pos.y + 5.0f},
        {pos.x + (float)birdRadius + 10.0f, pos.y},
        rl::ORANGE
    );

    // Eye
    rl::draw_circle_v({pos.x + (float)birdRadius / 3.0f, pos.y - (float)birdRadius / 3.0f}, 5.0f, rl::WHITE);
    rl::draw_circle_v({pos.x + (float)birdRadius / 3.0f, pos.y - (float)birdRadius / 3.0f}, 2.0f, rl::BLACK);

    // Wing
    float wingAngle = wingUp ? -15.0f : 15.0f;
    rl::draw_triangle(
        {pos.x - 5.0f, pos.y},
        {pos.x - 25.0f, pos.y + wingAngle},
        {pos.x - 5.0f, pos.y + 10.0f},
        rl::BROWN
    );
}

fn void draw_pipe(float x, float gapY, int gapHalf) {
    // Pipe
    rl::draw_rectangle((int)x, 0, 60, (int)(gapY - (float)gapHalf), rl::GREEN);
    rl::draw_rectangle((int)x, (int)(gapY + (float)gapHalf), 60, WINDOW_HEIGHT - (int)(gapY + (float)gapHalf) - 40, rl::GREEN);

    // Pipe Cap
    rl::draw_rectangle((int)x - 5, (int)(gapY - (float)gapHalf) - 20, 70, 20, rl::DARKGREEN);
    rl::draw_rectangle((int)x - 5, (int)(gapY + (float)gapHalf), 70, 20, rl::DARKGREEN);
}

fn void draw_ground_trees(float[] treeX) {
    for (int i = 0; i < treeX.len; i++) {
        float baseY = (float)WINDOW_HEIGHT - 40.0f;
        rl::draw_rectangle((int)treeX[i] - 5, (int)baseY - 30, 10, 30, rl::BROWN);
        rl::draw_circle_v({(int)treeX[i], (float)((int)baseY - 40)}, 15.0f, rl::DARKGREEN);
    }
}

fn void draw_clouds(Vec2[] clouds) {
    for (int i = 0; i < clouds.len; i++) {
        rl::draw_circle_v({clouds[i].x, clouds[i].y}, 20.0f, rl::LIGHTGRAY);
        rl::draw_circle_v({clouds[i].x + 20.0f, clouds[i].y + 5.0f}, 18.0f, rl::LIGHTGRAY);
        rl::draw_circle_v({clouds[i].x - 20.0f, clouds[i].y + 5.0f}, 18.0f, rl::LIGHTGRAY);
    }
}

fn void game_frame() @wasm {
    float dt = rl::get_frame_time();
    gameTime += dt;

    // Input
    switch {
        case (rl::is_key_pressed(rl::KEY_SPACE) || rl::is_key_pressed(rl::KEY_UP)):
            birdVel += flapImpulse;
            birdVel = clamp(birdVel, (Vec2){0, -650}, (Vec2){0,0});
        // case (rl::is_mouse_button_down(rl::MouseButton.LEFT)):
        //     birdVel += flapImpulse / 14;
        //     birdVel = math::clamp(birdVel, (Vec2){0, -650}, (Vec2){0,0});
        // case (rl::is_mouse_button_down(rl::MouseButton.RIGHT) || rl::is_key_pressed(rl::KEY_DOWN)):
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
        pipeGapY = (float)rl::get_random_value(0, (WINDOW_HEIGHT - 200)) + 100.0f;
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

    rl::@drawing()
    {
        rl::clear_background(rl::SKYBLUE);

        draw_clouds(clouds);
        draw_ground_trees(treeX);

        // Ground? sure
        rl::draw_rectangle(0, WINDOW_HEIGHT - 40, WINDOW_WIDTH, 40, rl::BROWN);

        draw_pipe(pipeX, pipeGapY, gapHalf);
        draw_bird(birdPos, wingUp);

        // Score
        rl::draw_text(string::tformat_zstr("Score: %d", score), 10, 10, 30, rl::BLACK);
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
        rl::@drawing()
        {
            rl::clear_background(rl::RED);
        };
    }
}

fn void main() @extern("main") @wasm {
    runtime::wasm_initialize();
    rl::init_window(WINDOW_WIDTH, WINDOW_HEIGHT, "Flappy Bird in C3 - Enhanced");
    rl::set_target_fps(60);

    rl::raylib_js_set_entry(&game_frame);
}

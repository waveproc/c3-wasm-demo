// c3c compile -D PLATFORM_WEB --reloc=none --target wasm32 -O3 -g0 --link-libc=no --use-stdlib=no --no-entry -o demo -z --export-table test.c3 rl.c3
import rl;

struct Game {
    int test;
}

fn void game_frame() @wasm
{
    float dt = rl::get_frame_time();
    rl::begin_drawing();
        rl::clear_background(rl::SKYBLUE);
        rl::draw_rectangle_v({0,0}, {100,100}, rl::GREEN);
        rl::draw_circle_v({(float)rl::get_screen_width() / 2, (float)rl::get_screen_height() / 2}, 50, rl::YELLOW);
    rl::end_drawing();
}

fn void main() @extern("main") @wasm
{
    rl::init_window(800, 600, "test.c3");
    rl::set_target_fps(60);

    rl::raylib_js_set_entry(&game_frame);
}

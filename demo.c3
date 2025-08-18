// c3c compile -D PLATFORM_WEB --reloc=none --target wasm32 -O3 -g0 --link-libc=no --use-stdlib=no --no-entry -o demo -z --export-table demo.c3 rl.c3
import rl;

Object[20] objects;

const Vec2 PLAYER_SIZE = {100, 100};
const Vec2 GRAVITY = {0, 1000};
const int N = 10;
const float COLLISION_DAMP = 1;

struct Object {
    Vec2 position;
    Vec2 velocity;
    Color color;
}

fn void Object.randomize(Object *obj) {
    obj.position = {
        // TODO: Casting to int is wrong. It would be better to have
        // an RNG that generates floats 0..1 in the first place.
        rl::get_random_value(0, rl::get_screen_width() - (int)PLAYER_SIZE.x),
        rl::get_random_value(0, rl::get_screen_height() - (int)PLAYER_SIZE.y)
    };
    obj.velocity = {200, 200};
    obj.color = rl::color_from_hsv(360*((float)rl::get_random_value(0, 100)/100.0), 1, 1);
}

fn void game_frame() @wasm
{
    float dt = rl::get_frame_time();
    rl::begin_drawing();
        rl::clear_background(rl::ORIG_BLACK);
        foreach (&object: objects) {
            object.velocity += GRAVITY*dt;
            float nx = object.position.x + object.velocity.x*dt;
            if (nx < 0 || nx + PLAYER_SIZE.x > rl::get_screen_width()) {
                object.velocity.x *= -COLLISION_DAMP;
                object.color = rl::color_from_hsv(360*((float)rl::get_random_value(0, 100)/100.0), 1, 1);
            } else {
                object.position.x = nx;
            }
            float ny = object.position.y + object.velocity.y*dt;
            if (ny < 0 || ny + PLAYER_SIZE.y > rl::get_screen_height()) {
                object.velocity.y *= -COLLISION_DAMP;
                object.color = rl::color_from_hsv(360*((float)rl::get_random_value(0, 100)/100.0), 1, 1);
            } else {
                object.position.y = ny;
            }

            rl::draw_rectangle_v(object.position, PLAYER_SIZE, object.color);
        }
    rl::end_drawing();
}

fn void main() @extern("main") @wasm
{
    rl::init_window(800, 600, "Hello, from C3 WebAssembly");
    rl::set_target_fps(60);

    foreach (&object: objects) {
        object.randomize();
    }
    
    $if $feature(PLATFORM_WEB):
        rl::raylib_js_set_entry(&game_frame);
    $else
        while (!rl::window_should_close()) {
            game_frame();
        }
        rl::close_window();
    $endif
}

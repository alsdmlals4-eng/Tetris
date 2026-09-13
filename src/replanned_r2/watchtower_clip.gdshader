shader_type canvas_item;
// Source-space atlas clipping only: no source pixel authoring or time animation.
uniform bool keep_left = true;
uniform float split_y;
uniform float upper_x;
uniform float lower_x;
void fragment() {
    vec2 source_pixel = UV / TEXTURE_PIXEL_SIZE;
    float split_x = source_pixel.y < split_y ? upper_x : lower_x;
    if ((keep_left && source_pixel.x >= split_x) || (!keep_left && source_pixel.x < split_x)) {
        COLOR.a = 0.0;
    }
}

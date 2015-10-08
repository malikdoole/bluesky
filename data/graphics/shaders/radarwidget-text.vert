#version 330
#define VERTEX_IS_LATLON 0
#define VERTEX_IS_METERS 1
#define VERTEX_IS_SCREEN 2
#define VERTEX_IS_GLXY   3
#define DEG2RAD 0.01745329252

// Uniform block of global data
layout (std140) uniform global_data {
int wrap_dir;           // Wrap-around direction
float wrap_lon;         // Wrap-around longitude
float panlat;           // Map panning coordinates [deg]
float panlon;           // Map panning coordinates [deg]
float zoom;             // Screen zoom factor [-]
int screen_width;       // Screen width in pixels
int screen_height;      // Screen height in pixels
int vertex_scale_type;  // Vertex scale type
};

// Local uniform data
uniform vec2 char_size;         // Size (wxh) of a character
uniform ivec2 block_size;         // Textblock width and height in #characters


layout (location = 0) in vec2 vertex_in;
layout (location = 1) in vec3 texcoords_in;
layout (location = 2) in float lat_in;
layout (location = 3) in float lon_in;
layout (location = 4) in float orientation_in;
layout (location = 5) in vec3 color_in;
layout (location = 6) in float texdepth_in;

out vec3 texcoords_fs;
out vec3 color_fs;

void main() {
    // Pass color and texture coordinates to the fragment shader
    color_fs = color_in;
    texcoords_fs = texcoords_in;
    texcoords_fs.p -= 32.0;

    vec2 vAR = vec2(1.0, float(screen_width) / float(screen_height));
    vec2 flat_earth = vec2(cos(DEG2RAD*panlat), 1.0);
    mat2 mrot = mat2(cos(DEG2RAD*orientation_in), -sin(DEG2RAD*orientation_in), sin(DEG2RAD*orientation_in), cos(DEG2RAD*orientation_in));

    vec2 position = vec2(lon_in, lat_in);
    if (wrap_dir < -0.1 && position.x > wrap_lon) {
        position.x -= 360.0;
    } else if (wrap_dir > 0.1 && position.x < wrap_lon) {
        position.x += 360.0;
    }
    position -= vec2(panlon, panlat);
    position *= (zoom * flat_earth);

    vec2 vertex = mrot * vertex_in;

    // When text_dims is non-zero we are drawing instanced
    if (block_size[0] > 0) {
        texcoords_fs.p = texdepth_in - 32.0;
        vertex.x += float(gl_InstanceID%block_size[0]) * char_size.x;
        vertex.y -= floor(float((gl_InstanceID%(block_size[0]*block_size[1])))/block_size[0]) * char_size.y;
    }
    switch (vertex_scale_type) {
        case VERTEX_IS_SCREEN:
            vertex = vec2(2.0 * vertex.x / float(screen_width), 2.0 * vertex.y / float(screen_height));
            gl_Position = vec4(vAR * position + vertex, 0.0, 1.0);
            break;
        default:
        case VERTEX_IS_GLXY:
            gl_Position = vec4(mrot * vertex_in, 0.0, 1.0);
            break;
    }
}
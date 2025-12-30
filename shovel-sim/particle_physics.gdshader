shader_type canvas_item;

// Input: current particle state
uniform sampler2DArray particle_texture : filter_nearest;
uniform int current_layer : hint_range(0, 128) = 0;

// Simulation parameters
uniform vec3 gravity = vec3(0.0, -9.8, 0.0);
uniform float delta_time = 0.016;
uniform vec3 grid_resolution = vec3(64.0, 64.0, 64.0);

// Material properties lookup (will expand this later)
const float FRICTION_SAND = 0.5;
const float FRICTION_DIRT = 0.7;
const float FRICTION_MULCH = 0.8;

// Decode particle data from RGBA8
struct Particle {
    int material_type;
    vec3 velocity;
};

Particle decode_particle(vec4 data) {
    Particle p;
    p.material_type = int(data.r * 255.0);
    // Decode velocity from 0-255 range to -2.0 to +2.0 m/s range
    p.velocity.x = (data.g - 0.5) * 4.0;
    p.velocity.y = (data.b - 0.5) * 4.0;
    p.velocity.z = (data.a - 0.5) * 4.0;
    return p;
}

vec4 encode_particle(Particle p) {
    vec4 data;
    data.r = float(p.material_type) / 255.0;
    // Encode velocity from -2.0 to +2.0 m/s range to 0-255
    data.g = clamp(p.velocity.x / 4.0 + 0.5, 0.0, 1.0);
    data.b = clamp(p.velocity.y / 4.0 + 0.5, 0.0, 1.0);
    data.a = clamp(p.velocity.z / 4.0 + 0.5, 0.0, 1.0);
    return data;
}

float get_friction(int material_type) {
    if (material_type == 1) return FRICTION_SAND;
    if (material_type == 2) return FRICTION_DIRT;
    if (material_type == 3) return FRICTION_MULCH;
    return 0.5;
}

void fragment() {
    // Get current pixel position (this represents x,y in the current z-layer)
    vec2 uv = UV;
    ivec2 grid_pos_2d = ivec2(uv * vec2(grid_resolution.xy));

    // Read current particle state
    vec4 current_data = texture(particle_texture, vec3(uv, float(current_layer)));
    Particle particle = decode_particle(current_data);

    // Only update non-empty particles
    if (particle.material_type != 0) {
        // Apply gravity
        particle.velocity += gravity * delta_time;

        // Apply friction/damping
        float friction = get_friction(particle.material_type);
        float damping = 1.0 - (friction * delta_time);
        particle.velocity *= damping;

        // Clamp velocity to prevent instability
        float max_velocity = 5.0;
        particle.velocity = clamp(particle.velocity, vec3(-max_velocity), vec3(max_velocity));

        // Output updated particle state
        COLOR = encode_particle(particle);
    } else {
        // Empty particle, just pass through
        COLOR = current_data;
    }
}
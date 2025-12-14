#[compute]
#version 450

layout(binding = 0) buffer HeightData {
    float heights[];
};

layout(binding = 1) buffer TypeData {
    int types[];
};

layout(binding = 2) buffer Params {
    float repose;
    float flow_rate;
};

layout(binding = 3) buffer GridParams {
    int grid_width;
    int grid_height;
};

// Compute shader entry point
layout(local_size_x = 8, local_size_y = 8) in;

float pseudo_random(int seed) {
    return fract( sin(float(seed) * 43748.5453) * 10000.0 ) ;
}

void main() {
    ivec2 gid = ivec2(gl_GlobalInvocationID.xy); // get global invocation ID

    // bounds check
    if (gid.x >= grid_width || gid.y >= grid_height) {
        return;
    }

    int index = gid.y * grid_width + gid.x;

    float h = heights[index];
    int cellType = types[index];

    // skip empty cells
    if (h <= 0.0) {
        return;
    }

    // update height based on neighbors
    vec2 offsets[8]; // Declare the array first
    offsets[0] = vec2(-1, 0); // Left
    offsets[1] = vec2(1, 0); // Right
    offsets[2] = vec2(0, -1); // Down
    offsets[3] = vec2(0, 1); // Up
    offsets[4] = vec2(-1, -1); // Down-left
    offsets[5] = vec2(1, -1); // Down-right
    offsets[6] = vec2(-1, 1); // Up-left
    offsets[7] = vec2(1, 1); // Up-right

    // randomly ordered indices
    int random_indices[8];
    for (int i = 0; i < 8; i++) {
        random_indices[i] = i;
    }

    for (int i = 0; i < 8; i++) {
        int v = int(gid.y * grid_width + gid.x + i) * ( 8 - i ) ;
        int randIndex = int(pseudo_random(v));

        // swap current index with random index
        int temp = random_indices[i];
        random_indices[i] = random_indices[randIndex];
        random_indices[randIndex] = temp;
    }

    for ( int i = 0; i < 8 ; i ++ ) {
        int neighborIndex = random_indices[i];
        ivec2 neighborCoord = gid + ivec2(offsets[neighborIndex]);

        if ( neighborCoord . x >= 0 && neighborCoord . x < grid_width &&
            neighborCoord . y >= 0 && neighborCoord . y < grid_height ) {
            
            int neighborIndexLinear = neighborCoord.y * grid_width + neighborCoord.x;
            float neighborHeight = heights[neighborIndexLinear];
            float diff = h - neighborHeight;

            // only move material if the slope exceeds angle of repose
            if ( diff > repose ) {
                float excess = diff - repose;
                float moveAmount = excess * flow_rate;

                heights[index] -= moveAmount;
                heights[neighborIndexLinear] += moveAmount;
                //break ; // exit after moving material?
            }
        }
    }
}

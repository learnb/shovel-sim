#[compute]
#version 450

layout(binding = 0) buffer HeightData {
    float heights[];
};

layout(binding = 1) buffer TypeData {
    int types[];
};

const int GRID_WIDTH = 128;
const int GRID_HEIGHT = 128;
const float REPOSE = 0.35;
const float FLOW_RATE = 0.05;

// Compute shader entry point
layout(local_size_x = 8, local_size_y = 8) in;

float pseudo_random(int seed) {
    return fract( sin(float(seed) * 43748.5453) * 10000.0 ) ;
}

void main() {
    ivec2 gid = ivec2(gl_GlobalInvocationID.xy); // get global invocation ID

    // bounds check
    if (gid.x >= GRID_WIDTH || gid.y >= GRID_HEIGHT) {
        return;
    }

    int index = gid.y * GRID_WIDTH + gid.x;

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
        int v = int(gid.y * GRID_WIDTH + gid.x + i) * ( 8 - i ) ;
        int randIndex = int(pseudo_random(v));

        // swap current index with random index
        int temp = random_indices[i];
        random_indices[i] = random_indices[randIndex];
        random_indices[randIndex] = temp;
    }

    for ( int i = 0; i < 8 ; i ++ ) {
        int neighborIndex = random_indices[i];
        ivec2 neighborCoord = gid + ivec2(offsets[neighborIndex]);

        if ( neighborCoord . x >= 0 && neighborCoord . x < GRID_WIDTH &&
            neighborCoord . y >= 0 && neighborCoord . y < GRID_HEIGHT ) {
            
            int neighborIndexLinear = neighborCoord.y * GRID_WIDTH + neighborCoord.x;
            float neighborHeight = heights[neighborIndexLinear];
            float diff = h - neighborHeight;

            // only move material if the slope exceeds angle of repose
            if ( diff > REPOSE ) {
                float excess = diff - REPOSE;
                float moveAmount = excess * FLOW_RATE;

                heights[index] -= moveAmount;
                heights[neighborIndexLinear] += moveAmount;
                //break ; // exit after moving material?
            }
        }
    }
}

#[compute]
#version 450

layout(binding = 0) buffer HeightData {
    float heights[];
};

layout(binding = 1) buffer TypeData {
    int types[];
};

const int GRID_WIDTH = 64;
const int GRID_HEIGHT = 64;
const float REPOSE = 0.5;
const float FLOW_RATE = 0.001;

// Compute shader entry point
layout(local_size_x = 8, local_size_y = 8) in;

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

    for (int i = 0; i < 8; i++) {
        ivec2 neighborCoord = gid + ivec2(offsets[i]);

        if (neighborCoord.x >= 0 && neighborCoord.x < GRID_WIDTH &&
                neighborCoord.y >= 0 && neighborCoord.y < GRID_HEIGHT) {
            int neighborIndex = neighborCoord.y * GRID_WIDTH + neighborCoord.x;
            float neighborHeight = heights[neighborIndex];

            float diff = h - neighborHeight;

            // only move material if the slope exceeds angle of repose
            if (diff > REPOSE) {
                float excess = diff - REPOSE;
                float moveAmount = excess * FLOW_RATE;

                heights[index] -= moveAmount;
                heights[neighborIndex] += moveAmount;
                break; // exit after moving material?
            }
        }
    }
}

# Notes

## Idea

Shovel simulation game. Inspiration was transferring mulch. 

The core idea was around the fact that it is easier to scoop up material when the shovel's angle matches the angle of the pile's slope. 

## 3D Simulation Approach

### 3D Texture-Based Particle Grid

- Use a Texture3D or layered Texture2DArray to represent a 3D voxel grid
- Each texel = one particle location in 3D space
- Grid defines the "sandbox" volume (e.g., 128x128x128 voxels)
- Each voxel stores: particle type, velocity (packed), and state flags

### Multi-Pass Shader System

- Pass 1: Physics update (gravity, velocity integration)
- Pass 2: Neighbor collision resolution (6 or 26 neighbors in 3D)
- Pass 3: Scene collision detection and response
- Ping-pong between two 3D texture buffers

### Scene Interaction Strategy

Hybrid Voxelized Scene + Dynamic Object Proxies

Static Geometry Handling:

- Voxelize static meshes (floors, walls, terrain) into a 3D collision texture
- One-time process, or re-run when static geometry changes
- Each voxel marked as "solid" (occupied) or "empty"
- Stored in separate texture from particles, sampled during particle updates

Dynamic Object Handling:

- Pass array of collision shapes via shader uniforms (max ~8-16 objects)
- Each object defined by: type (sphere/box/capsule), position, rotation, dimensions
- Particle shader performs analytical collision tests (point-vs-shape math)
- Updated every frame as objects move

Collision Resolution:

- Particle shader checks static voxel grid first (texture lookup)
- Then iterates through dynamic object array (uniform array)
- If collision detected, push particle out along collision normal
- Apply friction/bounce based on material properties

Benefits:

- Static checks: O(1) texture lookup, very fast
- Dynamic checks: Simple math, no extra textures needed
- Static geometry can be arbitrarily complex (voxel resolution permitting)
- Dynamic objects stay responsive without re-voxelization overhead

Trade-offs:

- Static geometry limited by voxel resolution (blocky approximation)
- Dynamic objects limited to simple primitive shapes
- Moving static objects requires re-voxelization (expensive)

## Challenges

Challenge: 3D neighbor checks are expensive (26 neighbors)
Solution: Check only 6 cardinal directions + gravity direction prioritized

Challenge: Texture3D is harder to work with than Texture2D
Solution: Use Texture2DArray where each layer = Z slice, easier to debug

Challenge: Dynamic object collision updates every frame
Solution: Limit to ~8-16 objects, use simple shapes, early-out tests

## TODO

### Phase 1: Foundation & Data Structures

1. Create GDScript manager node (ParticleSimulation3D.gd)

- [x] Set up basic Node3D scaffold
- [x] Define grid parameters (resolution, world bounds)
- [x] Create helper functions for world-space ↔ grid-space conversion

2. Set up texture buffers

- [x] Create ping-pong Texture2DArray pair (read/write buffers)
- [x] Initialize with empty state
- [x] Implement buffer swap logic

3. Create material property system

- [x] Define material types enum (Sand, Dirt, Mulch, etc.)
- [x] Create material properties data structure (density, friction, angle of repose, etc.)
- [x] Build material lookup texture or uniform array

### Phase 2: Basic Physics Simulation

4. Implement Pass 1 shader: Physics update

- [x] Apply gravity to particles
- [x] Integrate velocity
- [x] Basic damping/friction
- [x] Write to output texture


5. Set up shader pipeline infrastructure

- [x] Create SubViewport for shader rendering
- [x] Set up fullscreen quad rendering
- [x] Implement ping-pong texture swap
- [x] Get basic update loop working


6. Test with simple particle spawn

- [x] Add function to spawn particles at grid positions
- [x] Spawn a column of particles
- [ ] Verify they fall with gravity

### Phase 3: Particle Interactions

7. Implement Pass 2 shader: Neighbor collisions

- [ ] Check 6 cardinal direction neighbors
- [ ] Implement particle swapping logic (falling/flowing)
- [ ] Add material-specific behavior (angle of repose)


8. Add horizontal dispersion

- [ ] Implement lateral movement for granular flow
- [ ] Material-specific flow rates
- [ ] Test with pile formation


9. Refine physics behavior

- [ ] Tune material parameters
- [ ] Add velocity transfer between particles
- [ ] Test stability (particles shouldn't jitter/vibrate)



### Phase 4: Visualization

10. Create particle rendering system

- [ ] Set up instanced mesh rendering
- [ ] Vertex shader reads particle texture
- [ ] Cull empty particles
- [ ] Basic coloring by material type


11. Improve visual quality

- [ ] Add per-particle color variation
- [ ] Lighting/shading
- [ ] Optional: normal estimation from neighbors
- [ ] Camera controls for testing

### Phase 5: Interaction & Polish

12. Implement particle spawn/remove API

- [ ] Spawn particles in shapes (box, sphere, stream)
- [ ] Remove particles in regions
- [ ] Test with continuous "pouring" effect


13. Add debug visualization

 - [ ] Grid boundary visualization
 - [ ] Particle count display
 - [ ] Performance metrics
 - [ ] Toggle particle grid overlay


14. Performance optimization

- [ ] Profile shader performance
- [ ] Optimize texture formats
- [ ] Implement spatial partitioning if needed
- [ ] Add option for fixed timestep physics updates

### Phase 6: Scene Interaction

15. Implement static geometry voxelization

- [ ] Create voxelization utility
- [ ] Convert static meshes to collision texture
- [ ] Visualize voxelized collision geometry

16. Add Pass 3 shader: Static collision

- [ ] Sample static collision texture
- [ ] Push particles out of solid voxels
- [ ] Test with simple floor/walls


17. Implement dynamic object proxy system

- [ ] Define collision shape data structures
- [ ] Pass shapes as shader uniforms
- [ ] Implement analytical collision tests in shader


18. Create shovel prototype

- [ ] Model simple shovel collision shape
- [ ] Track shovel transform
- [ ] Test scooping interaction
- [ ] Tune shovel angle vs pile angle mechanics


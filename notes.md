# Notes

## Idea

Shovel simulation game. Inspiration was transferring mulch. 

The core idea was around the fact that it is easier to scoop up material when the shovel's angle matches the angle of the pile's slope. 

## TODO

- [ ] reimplement as vertex shader; multimesh shader
- [ ] implement spawning new material in a sim
- [ ] attaching a sim to objects
- [ ] implement various "material" types, each with their own parameters
- [ ] add way to drop in more material

## Done

- [x] hook up debug controls to compute shader sim
- [x] fix bias in compute shader by adding randomness to check directions
- [x] optimize rule processing as compute shader
- [x] add a few initial states to pick from
- [x] add camera controls
- [x] randomize neighbor checks to reduce bias
- [x] expose sim parameters as UI sliders

## Challenges

- How to enable sim to react to external forces (digging)
  - attach new sim objects (grids) to objects that will interact with other sims
  - will have to handle logic for how cell values interact
- How can multiple material types interact within a sim?

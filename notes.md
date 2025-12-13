# Notes

## Idea

Shovel simulation game. Inspiration was transferring mulch. 

The core idea was around the fact that it is easier to scoop up material when the shovel's angle matches the angle of the pile's slope. 

## TODO

- [ ] optimize rule processing as compute shader
- [ ] implement various "material" types, each with their own parameters
- [ ] add way to drop in more material

## Done

- [x] add a few initial states to pick from
- [x] add camera controls
- [x] randomize neighbor checks to reduce bias
- [x] expose sim parameters as UI sliders

## Challenges

- How to enable sim to react to external forces (digging)
  - Can the sim interface with godot's physics?

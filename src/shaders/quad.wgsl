// This file is adapted from the Notochord WebGPU Agents course
// More info: twitter.com/arsiliath

@group(0) @binding(0)  
var<storage, read_write> pixels : array<vec4f>;

@group(0) @binding(1)
var<uniform> resolution : vec2f;

struct VertexOutput {
  @builtin(position) Position : vec4f,
    @location(0) fragUV : vec2f,
}

@vertex
fn vert(@builtin(vertex_index) VertexIndex : u32) -> VertexOutput {

  const pos = array(
    vec2( 1.0,  1.0),
    vec2( 1.0, -1.0),
    vec2(-1.0, -1.0),
    vec2( 1.0,  1.0),
    vec2(-1.0, -1.0),
    vec2(-1.0,  1.0),
  );

  const uv = array(
    vec2(1.0, 0.0),
    vec2(1.0, 1.0),
    vec2(0.0, 1.0),
    vec2(1.0, 0.0),
    vec2(0.0, 1.0),
    vec2(0.0, 0.0),
  );

  var output : VertexOutput;
  output.Position = vec4(pos[VertexIndex], 0.0, 1.0);
  output.fragUV = uv[VertexIndex];
  return output;
}

@fragment
fn frag(@location(0) fragUV : vec2f) -> @location(0) vec4f {
  var color = vec4(0, 0, 0, 1.0);
  color += pixels[i32((fragUV.x * resolution.x) + (floor(fragUV.y * resolution.y) * resolution.x))];
  return color;
}
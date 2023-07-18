@group(0) @binding(0)
  var<storage, read_write> pixels : array<vec4f>;

@group(0) @binding(1)
  var<uniform> resolution : vec2f;

// Uniforms
struct Uniforms {
  time: f32,
  count: u32,
  mouse_position: vec2f,
}

@group(1) @binding(0) 
  var<uniform> uniforms : Uniforms;

// Storages
@group(2) @binding(0)  
  var<storage, read_write> positions : array<vec2f>;

@group(2) @binding(1)  
  var<storage, read_write> velocities : array<vec2f>;


fn r(n: f32) -> f32 {
  let x = sin(n) * 43758.5453;
  return fract(x);
}

fn index(p: vec2f) -> i32 {
  return i32(p.x) + (i32(p.y) * i32(resolution.x));
}

@compute @workgroup_size(256)
fn reset(@builtin(global_invocation_id) id : vec3u) {
  let seed = f32(id.x)/f32(uniforms.count);
  var p = vec2(r(seed), r(seed + 0.1));
  p *= resolution;

  positions[id.x] = p;
  velocities[id.x] = vec2(r(f32(id.x+1)), r(f32(id.x + 2))) - 0.5;
}

@compute @workgroup_size(256)
fn simulate(@builtin(global_invocation_id) id : vec3u) {
  var p = positions[id.x];
  var v = velocities[id.x];

  var d = uniforms.mouse_position - p;
  var l = length(d);

  var m = 100.0 / (l * l);
  v += clamp(normalize(d) * m, vec2f(-0.1, -0.1), vec2f(0.1, 0.1));
  p += v;
  p = (p + resolution) % resolution;
  v = v * 0.99;

  positions[id.x] = p;
  velocities[id.x] = v;
  var r = clamp((abs(v.x) + abs(v.y)) / 0.9, 0.0, 1.0);

  pixels[index(p)] = vec4(r, clamp(1.0 - r, 0.0, 0.2), clamp(1.0 - r, 0.0, 0.3), 1.0);
}


@compute @workgroup_size(256)
fn fade(@builtin(global_invocation_id) id : vec3u) {
  pixels[id.x] *= 0.90;
}
@group(0) @binding(0)
  var<storage, read_write> pixels : array<vec4f>;

@group(0) @binding(1)
  var<uniform> resolution : vec2f;

// Uniforms
struct Uniforms {
  time: f32,
  count: u32,
  velocity: f32,
  detection_distance: f32,
  fixed_rotation: f32,
  relative_rotation: f32,
}

@group(1) @binding(0) 
  var<uniform> uniforms : Uniforms;

// Storages
@group(2) @binding(0)  
  var<storage, read_write> positions : array<vec2f>;

@group(2) @binding(1)  
  var<storage, read_write> headings : array<f32>;


fn r(n: f32) -> f32 {
  let x = sin(n) * 43758.5453;
  return fract(x);
}

fn index(p: vec2f) -> i32 {
  return i32(p.x) + (i32(p.y) * i32(resolution.x));
}

fn angleBetween(a: vec2f, b: vec2f) -> f32 {
  return atan2(b.y, b.x) - atan2(a.y, a.x);
}

fn isOnRightSide(p : vec2f, v : vec2f, op : vec2f) -> bool {
  var b = p + v;
  return ((b.x - p.x) * (op.y - p.y) - (b.y - p.y) * (op.x - p.x)) > 0;
}

@compute @workgroup_size(256)
fn reset(@builtin(global_invocation_id) id : vec3u) {
  let seed = f32(id.x)/f32(uniforms.count);

  var p = vec2(r(seed), r(seed + 0.1)) * resolution;
  var h = radians(mix(0.0, 360.0, r(seed + 0.2)));

  positions[id.x] = p;
  headings[id.x] = h;
}

@compute @workgroup_size(256)
fn simulate(@builtin(global_invocation_id) id : vec3u) {
  let a = radians(uniforms.fixed_rotation);
  let b = radians(uniforms.relative_rotation);
  
  var p = positions[id.x];
  var h = headings[id.x];
  var v = vec2(cos(h), sin(h));
  
  var l = 0.0;
  var r = 0.0;
  for (var i = 0u; i < uniforms.count; i++) {
    if i == id.x { continue; }

    let other = positions[i];
    let d = distance(p, other);

    if (d > uniforms.detection_distance) { continue; }

    if (isOnRightSide(p, v, other)) {
      r += 1.0;
    } else {
      l += 1.0;
    }
  }

  let n = r + l;
  var delta_phi = a + b * n * sign(r - l);
  h += delta_phi;
  p += normalize(v) * uniforms.velocity;

  positions[id.x] = p;
  headings[id.x] = h;

  pixels[index(p)] = vec4(1.0);
}


@compute @workgroup_size(256)
fn fade(@builtin(global_invocation_id) id : vec3u) {
  pixels[id.x] *= 0.95;
}
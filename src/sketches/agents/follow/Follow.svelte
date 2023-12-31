<script lang="ts">
  import { onMount } from "svelte";
  import { makeShaderDataDefinitions, makeStructuredView } from "webgpu-utils";
  import followShaderCode from "./follow.wgsl?raw";
  import { SIZES } from "../../../lib/sizes";
  import { createPixelBufferRenderer } from "../../../lib/render";
  import { createShader } from "../../../lib/shader";

  interface Uniforms {
    time: number;
    count: number;
    mouse_position: [number, number];
  }

  const NOOP = () => {};
  const WIDTH = 1280;
  const HEIGHT = 720;
  const UNIFORMS: Uniforms = {
    time: 0,
    count: 40000,
    mouse_position: [0, 0],
  };
  const SETTINGS = {
    pixelWorkgroups: Math.ceil((WIDTH * HEIGHT) / 256),
    agentWorkgroups: Math.ceil(UNIFORMS.count / 256),
  };

  let canvas: HTMLCanvasElement;
  let handleMouseMove: (x: number, y: number) => void = NOOP;

  async function init() {
    if (!canvas) return;

    const adapter = await navigator.gpu?.requestAdapter();
    const device = await adapter?.requestDevice();

    if (!device) {
      throw new Error("need a browser that supports WebGPU");
    }

    canvas.width = WIDTH;
    canvas.height = HEIGHT;
    const context = canvas.getContext("webgpu");
    const format = navigator.gpu.getPreferredCanvasFormat();
    context.configure({ device, format });

    const visibility = GPUShaderStage.COMPUTE;

    const defs = makeShaderDataDefinitions(followShaderCode);
    const uniformValues = makeStructuredView(defs.uniforms.uniforms);
    const resolutionValues = makeStructuredView(defs.uniforms.resolution);

    uniformValues.set(UNIFORMS);
    resolutionValues.set([WIDTH, HEIGHT]);

    // Pixel buffer
    const pixelBuffer = device.createBuffer({
      size: WIDTH * HEIGHT * SIZES.vec4,
      usage: GPUBufferUsage.STORAGE,
    });

    const resolutionBuffer = device.createBuffer({
      size: resolutionValues.arrayBuffer.byteLength,
      usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
    });

    const renderLayout = device.createBindGroupLayout({
      entries: [
        { visibility, binding: 0, buffer: { type: "storage" } },
        { visibility, binding: 1, buffer: { type: "uniform" } },
      ],
    });
    const renderBuffersBindGroup = device.createBindGroup({
      layout: renderLayout,
      entries: [
        { binding: 0, resource: { buffer: pixelBuffer } },
        { binding: 1, resource: { buffer: resolutionBuffer } },
      ],
    });

    // Uniform buffer
    const uniformsBuffer = device.createBuffer({
      size: uniformValues.arrayBuffer.byteLength,
      usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
    });

    const uniformsLayout = device.createBindGroupLayout({
      entries: [{ visibility, binding: 0, buffer: { type: "uniform" } }],
    });
    const uniformsBufferBindGroup = device.createBindGroup({
      layout: uniformsLayout,
      entries: [{ binding: 0, resource: { buffer: uniformsBuffer } }],
    });

    // Other buffers
    const positionsBuffer = device.createBuffer({
      size: SIZES.vec2 * UNIFORMS.count,
      usage: GPUBufferUsage.STORAGE,
    });

    const velocitiesBuffer = device.createBuffer({
      size: SIZES.vec2 * UNIFORMS.count,
      usage: GPUBufferUsage.STORAGE,
    });

    const agentsLayout = device.createBindGroupLayout({
      entries: [
        { visibility, binding: 0, buffer: { type: "storage" } },
        { visibility, binding: 1, buffer: { type: "storage" } },
      ],
    });
    const agentsBuffersBindGroup = device.createBindGroup({
      layout: agentsLayout,
      entries: [
        { binding: 0, resource: { buffer: positionsBuffer } },
        { binding: 1, resource: { buffer: velocitiesBuffer } },
      ],
    });

    device.queue.writeBuffer(resolutionBuffer, 0, resolutionValues.arrayBuffer);
    device.queue.writeBuffer(uniformsBuffer, 0, uniformValues.arrayBuffer);

    /////
    // Overall memory layout
    const layout = device.createPipelineLayout({
      bindGroupLayouts: [renderLayout, uniformsLayout, agentsLayout],
    });

    const shaderModule = await createShader({
      device,
      label: "follow shader module",
      code: followShaderCode,
    });

    const resetPipeline = device.createComputePipeline({
      layout,
      compute: { module: shaderModule, entryPoint: "reset" },
    });

    const simulatePipeline = device.createComputePipeline({
      layout,
      compute: { module: shaderModule, entryPoint: "simulate" },
    });

    const fadePipeline = device.createComputePipeline({
      layout,
      compute: { module: shaderModule, entryPoint: "fade" },
    });

    const render = createPixelBufferRenderer({
      device,
      context,
      pixelBuffer,
      resolutionBuffer,
    });

    const _reset = () => {
      const encoder = device.createCommandEncoder();
      const pass = encoder.beginComputePass();
      pass.setPipeline(resetPipeline);
      pass.setBindGroup(0, renderBuffersBindGroup);
      pass.setBindGroup(1, uniformsBufferBindGroup);
      pass.setBindGroup(2, agentsBuffersBindGroup);
      pass.dispatchWorkgroups(SETTINGS.agentWorkgroups);
      pass.end();
      device.queue.submit([encoder.finish()]);
    };

    const _draw = () => {
      const encoder = device.createCommandEncoder();
      const pass = encoder.beginComputePass();
      pass.setBindGroup(0, renderBuffersBindGroup);
      pass.setBindGroup(1, uniformsBufferBindGroup);
      pass.setBindGroup(2, agentsBuffersBindGroup);

      pass.setPipeline(fadePipeline);
      pass.dispatchWorkgroups(SETTINGS.pixelWorkgroups);

      pass.setPipeline(simulatePipeline);
      pass.dispatchWorkgroups(SETTINGS.agentWorkgroups);

      pass.end();

      // Render the pixels buffer to the canvas
      render(encoder);

      device.queue.submit([encoder.finish()]);

      UNIFORMS.time += 1;
      uniformValues.set(UNIFORMS);
      device.queue.writeBuffer(uniformsBuffer, 0, uniformValues.arrayBuffer);

      requestAnimationFrame(_draw);
    };

    const _setMousePos = (x: number, y: number) => {
      UNIFORMS.mouse_position = [x, y];
      uniformValues.set(UNIFORMS);
      device.queue.writeBuffer(uniformsBuffer, 0, uniformValues.arrayBuffer);
    };

    return { reset: _reset, draw: _draw, setMousePos: _setMousePos };
  }

  onMount(async () => {
    const { reset, draw, setMousePos } = await init();
    reset();
    draw();
    handleMouseMove = setMousePos;
  });
</script>

<canvas
  bind:this={canvas}
  on:mousemove={({ offsetX, offsetY, target }) => {
    handleMouseMove(
      (offsetX * WIDTH) / canvas.offsetWidth,
      (offsetY * HEIGHT) / canvas.offsetHeight
    );
  }}
  on:mouseleave={() => {
    handleMouseMove(0, 0);
  }}
/>

<style>
  canvas {
    width: 100%;
    height: 100%;
  }
</style>

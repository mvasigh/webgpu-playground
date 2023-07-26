<script lang="ts">
  import { onMount } from "svelte";
  import { makeShaderDataDefinitions, makeStructuredView } from "webgpu-utils";
  import ppsShaderCode from "./shader.wgsl?raw";
  import { SIZES } from "../../../lib/sizes";
  import { createPixelBufferRenderer } from "../../../lib/render";
  import { createShader } from "../../../lib/shader";

  interface Uniforms {
    time: number;
    count: number;
  }

  const NOOP = () => {};
  const WIDTH = 1280;
  const HEIGHT = 720;
  const UNIFORMS: Uniforms = {
    time: 0,
    count: 40000,
  };
  const SETTINGS = {
    pixelWorkgroups: Math.ceil((WIDTH * HEIGHT) / 256),
    agentWorkgroups: Math.ceil(UNIFORMS.count / 256),
  };

  let canvas: HTMLCanvasElement;

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

    const defs = makeShaderDataDefinitions(ppsShaderCode);
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

    const headingsBuffer = device.createBuffer({
      size: SIZES.f32 * UNIFORMS.count,
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
        { binding: 1, resource: { buffer: headingsBuffer } },
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
      label: "pps shader module",
      code: ppsShaderCode,
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

    return { reset: _reset, draw: _draw };
  }

  onMount(async () => {
    const { reset, draw } = await init();
    reset();
    draw();
  });
</script>

<canvas bind:this={canvas} />

<style>
  canvas {
    width: 100%;
    height: 100%;
  }
</style>

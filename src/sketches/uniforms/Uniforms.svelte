<script lang="ts">
  import { onMount } from "svelte";
  import shader from "./shader.wgsl?raw";

  let canvas: HTMLCanvasElement;

  async function init() {
    // Check to see if user's browser supports WebGPU
    const adapter = await navigator.gpu?.requestAdapter();
    const device = await adapter?.requestDevice();

    if (!device) {
      throw new Error("need a browser that supports WebGPU");
    }

    // Get a WebGPU context from the canvas and configure it
    const context = canvas.getContext("webgpu");
    const presentationFormat = navigator.gpu.getPreferredCanvasFormat();
    context.configure({
      device,
      format: presentationFormat,
    });

    const uniformBufferSize =
      4 * 4 + // color is 4 32bit floats (4bytes each)
      2 * 4 + // scale is 2 32bit floats (4bytes each)
      2 * 4; // offset is 2 32bit floats (4bytes each)
    const uniformBuffer = device.createBuffer({
      size: uniformBufferSize,
      usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
    });

    // create a typedarray to hold the values for the uniforms in JavaScript
    const uniformValues = new Float32Array(uniformBufferSize / 4);

    // offsets to the various uniform values in float32 indices
    const kColorOffset = 0;
    const kScaleOffset = 4;
    const kOffsetOffset = 6;

    uniformValues.set([0, 1, 1, 1], kColorOffset); // set the color
    uniformValues.set([-0.23, -0.25], kOffsetOffset); // set the offset

    // Create the shader module (contains vertex and fragment shader)
    const module = device.createShaderModule({
      label: `basic shader with hard-coded red triangle`,
      code: shader,
    });

    // Create the render pipeline
    const renderPipeline = device.createRenderPipeline({
      label: `basic hard-coded triangle pipeline`,
      layout: "auto",
      vertex: {
        module,
        entryPoint: "vs",
      },
      fragment: {
        module,
        entryPoint: "fs",
        targets: [{ format: presentationFormat }],
      },
    });

    const bindGroup = device.createBindGroup({
      layout: renderPipeline.getBindGroupLayout(0),
      entries: [{ binding: 0, resource: { buffer: uniformBuffer } }],
    });

    // Create the render pass descriptor which describes what textures will be drawn
    const renderPassDescriptor: GPURenderPassDescriptor = {
      label: `hard-coded triangle renderPass`,
      colorAttachments: [
        {
          view: context.getCurrentTexture().createView(),
          clearValue: [0.1, 0.1, 0.1, 1],
          loadOp: "clear",
          storeOp: "store",
        },
      ],
    };

    function render() {
      if (!canvas) return;

      // Set the uniform values in our JavaScript side Float32Array
      const aspect = canvas.width / canvas.height;
      uniformValues.set([0.5 / aspect, 0.5], kScaleOffset); // set the scale

      // copy the values from JavaScript to the GPU
      device.queue.writeBuffer(uniformBuffer, 0, uniformValues);

      // Get the current texture from the canvas context and
      // set it as the texture to render to.
      renderPassDescriptor.colorAttachments[0].view = context
        .getCurrentTexture()
        .createView();
      const encoder = device.createCommandEncoder({ label: "render encoder" });
      const pass = encoder.beginRenderPass(renderPassDescriptor);
      pass.setPipeline(renderPipeline);
      pass.setBindGroup(0, bindGroup);
      pass.draw(3);
      pass.end();

      const commandBuffer = encoder.finish();

      device.queue.submit([commandBuffer]);
    }

    const observer = new ResizeObserver((entries) => {
      for (let entry of entries) {
        const canvas = entry.target as HTMLCanvasElement;
        const width = entry.contentBoxSize[0].inlineSize;
        const height = entry.contentBoxSize[0].blockSize;
        canvas.width = Math.max(
          1,
          Math.min(width, device.limits.maxTextureDimension2D)
        );
        canvas.height = Math.max(
          1,
          Math.min(height, device.limits.maxTextureDimension2D)
        );

        render();
      }
    });

    render();
    observer.observe(canvas);
  }

  onMount(() => {
    init();
  });
</script>

<canvas bind:this={canvas} />

<style>
  canvas {
    width: 100%;
    height: 100%;
  }
</style>

<script lang="ts">
  import { onMount } from "svelte";
  import shader from "./shader.wgsl?raw";

  let canvas: HTMLCanvasElement;

  async function main() {
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
      const encoder = device.createCommandEncoder({ label: "render encoder" });
      const pass = encoder.beginRenderPass(renderPassDescriptor);
      pass.setPipeline(renderPipeline);
      pass.draw(3);
      pass.end();

      const commandBuffer = encoder.finish();
      device.queue.submit([commandBuffer]);
    }

    render();
  }

  onMount(main);
</script>

<canvas bind:this={canvas} />

<style>
  canvas {
    width: 600px;
    height: 600px;
  }
</style>

<script lang="ts">
  import { onMount } from "svelte";
  import shader from "./shader.wgsl?raw";

  const input = new Float32Array([1, 3, 5]);
  let output: Float32Array;

  async function main() {
    // Check to see if user's browser supports WebGPU
    const adapter = await navigator.gpu?.requestAdapter();
    const device = await adapter?.requestDevice();

    if (!device) {
      throw new Error("need a browser that supports WebGPU");
    }

    const module = device.createShaderModule({
      label: "doubling compute module",
      code: shader,
    });

    const pipeline = device.createComputePipeline({
      label: "doubling compute pipeline",
      layout: "auto",
      compute: {
        module,
        entryPoint: "computeSomething",
      },
    });

    // create a buffer on the GPU to hold our computation
    // input and output
    const workBuffer = device.createBuffer({
      label: "work buffer",
      size: input.byteLength,
      usage:
        GPUBufferUsage.STORAGE |
        GPUBufferUsage.COPY_SRC |
        GPUBufferUsage.COPY_DST,
    });

    // Copy our input data to that buffer
    device.queue.writeBuffer(workBuffer, 0, input);

    // create a buffer on the GPU to get a copy of the results
    const resultBuffer = device.createBuffer({
      label: "result buffer",
      size: input.byteLength,
      usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST,
    });

    // Setup a bindGroup to tell the shader which
    // buffer to use for the computation
    const bindGroup = device.createBindGroup({
      label: "bindGroup for work buffer",
      layout: pipeline.getBindGroupLayout(0),
      entries: [{ binding: 0, resource: { buffer: workBuffer } }],
    });

    // Encode commands to do the computation
    const encoder = device.createCommandEncoder({
      label: "doubling encoder",
    });
    const pass = encoder.beginComputePass({
      label: "doubling compute pass",
    });
    pass.setPipeline(pipeline);
    pass.setBindGroup(0, bindGroup);
    pass.dispatchWorkgroups(input.length);
    pass.end();

    // Encode a command to copy the results to a mappable buffer.
    encoder.copyBufferToBuffer(
      workBuffer,
      0,
      resultBuffer,
      0,
      resultBuffer.size
    );

    // Finish encoding and submit the commands
    const commandBuffer = encoder.finish();
    device.queue.submit([commandBuffer]);

    // Read the results
    await resultBuffer.mapAsync(GPUMapMode.READ);
    output = new Float32Array(resultBuffer.getMappedRange().slice(0));
    resultBuffer.unmap();
  }

  onMount(main);
</script>

<p>Input: {input}</p>
{#if output}
  <p>Output: {output}</p>
{/if}

<style>
  p {
    font-family: sans-serif;
    display: block;
  }
</style>

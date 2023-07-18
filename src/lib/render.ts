// Parts of this file are adapted from the Notochord WebGPU Agents course
// More info: twitter.com/arsiliath

import quadShaderCode from "../shaders/quad.wgsl?raw";

interface RenderBufferOptions {
  device: GPUDevice;
  context: GPUCanvasContext;
  pixelBuffer: GPUBuffer;
  resolutionBuffer: GPUBuffer;
  format?: GPUTextureFormat;
  clearValue?: GPUColor;
}

export function createPixelBufferRenderer({
  device,
  context,
  pixelBuffer,
  resolutionBuffer,
  format = "bgra8unorm",
  clearValue = { r: 0.0, g: 0.0, b: 0.0, a: 1.0 },
}: RenderBufferOptions) {
  const shaderModule = device.createShaderModule({
    label: "quad shader",
    code: quadShaderCode,
  });

  const renderPipeline = device.createRenderPipeline({
    layout: "auto",
    vertex: {
      module: shaderModule,
      entryPoint: "vert",
    },
    fragment: {
      module: shaderModule,
      entryPoint: "frag",
      targets: [
        {
          format: format,
        },
      ],
    },
    primitive: {
      topology: "triangle-list",
    },
  });

  const bindGroup = device.createBindGroup({
    layout: renderPipeline.getBindGroupLayout(0),
    entries: [
      {
        binding: 0,
        resource: { buffer: pixelBuffer },
      },
      {
        binding: 1,
        resource: { buffer: resolutionBuffer },
      },
    ],
  });

  return function render(commandEncoder: GPUCommandEncoder) {
    const renderPass = commandEncoder.beginRenderPass({
      colorAttachments: [
        {
          view: context.getCurrentTexture().createView(),
          clearValue,
          loadOp: "clear",
          storeOp: "store",
        },
      ],
    });
    renderPass.setPipeline(renderPipeline);
    renderPass.setBindGroup(0, bindGroup);
    renderPass.draw(6, 1, 0, 0);
    renderPass.end();
  };
}

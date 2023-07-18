// Parts of this file are adapted from the Notochord WebGPU Agents course
// More info: twitter.com/arsiliath

type CreateShaderOptions = { device: GPUDevice } & GPUShaderModuleDescriptor;

export async function createShader({
  device,
  ...descriptor
}: CreateShaderOptions) {
  const label =
    descriptor.label ||
    `Shader Module ${Math.random().toString(32).substring(2, 6)}`;

  const module = device.createShaderModule(descriptor);
  const info = await module.getCompilationInfo();
  if (info.messages.length > 0) {
    for (let message of info.messages) {
      console.warn(
        `${message.message} at file ${label} line ${message.lineNum}`
      );
    }
    throw new Error(`Could not compile ${label}`);
  }
  return module;
}

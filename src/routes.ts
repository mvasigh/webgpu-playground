import type { ComponentType } from "svelte";

import Triangle from "./sketches/triangle/Triangle.svelte";
import Compute from "./sketches/compute/Compute.svelte";

export const ROUTES: Array<{
  href: string;
  label: string;
  component: ComponentType;
}> = [
  {
    href: "/triangle",
    label: "Triangle",
    component: Triangle,
  },
  {
    href: "/compute",
    label: "Compute",
    component: Compute,
  },
];

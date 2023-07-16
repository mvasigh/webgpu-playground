import type { ComponentType } from "svelte";

import RedTriangle from "./sketches/basic/red-triangle/RedTriangle.svelte";
import BasicCompute from "./sketches/compute/basic-compute/BasicCompute.svelte";
import FancyTriangle from "./sketches/basic/fancy-triangle/FancyTriangle.svelte";
import Uniforms from "./sketches/basic/uniforms/Uniforms.svelte";

interface Route {
  href: string;
  label: string;
  component: ComponentType;
}

interface RouteCategory {
  label: string;
  routes: Route[];
}

export const ROUTE_CATEGORIES: RouteCategory[] = [
  {
    label: "Basic",
    routes: [
      {
        href: "/red-triangle",
        label: "Red Triangle",
        component: RedTriangle,
      },
      {
        href: "/fancy-triangle",
        label: "Fancy Triangle",
        component: FancyTriangle,
      },
      {
        href: "/uniforms",
        label: "Uniforms",
        component: Uniforms,
      },
    ],
  },
  {
    label: "Compute",
    routes: [
      {
        href: "/basic-compute",
        label: "Multiply by 2",
        component: BasicCompute,
      },
    ],
  },
];

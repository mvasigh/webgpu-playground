import type { ComponentType } from "svelte";

import RedTriangle from "./sketches/red-triangle/RedTriangle.svelte";
import BasicCompute from "./sketches/basic-compute/BasicCompute.svelte";

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
    label: "Sketches",
    routes: [
      {
        href: "/red-triangle",
        label: "Red Triangle",
        component: RedTriangle,
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

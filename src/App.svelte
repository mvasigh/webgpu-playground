<script lang="ts">
  import Router, { link, location } from "svelte-spa-router";
  import { ROUTE_CATEGORIES } from "./routes";
</script>

<div class="root">
  <nav>
    <h1 class="title">WebGPU Playground</h1>
    <a class="github-link" href="https://github.com/mvasigh/webgpu-playground">
      View on Github
    </a>
    <hr />
    {#each ROUTE_CATEGORIES as { label, routes }}
      <h2 class="category-title">{label}</h2>
      <ul class="nav-list">
        {#each routes as { href, label }}
          <li class="nav-item" class:nav-item-active={$location === href}>
            <a use:link {href}>
              {label}
            </a>
          </li>
        {/each}
      </ul>
    {/each}
  </nav>

  <main>
    <Router
      routes={ROUTE_CATEGORIES.flatMap(({ routes }) => routes).reduce(
        (dict, { href, component }) => {
          dict[href] = component;
          return dict;
        },
        {}
      )}
    />
  </main>
</div>

<style>
  .root {
    display: grid;
    grid-template-columns: 300px 1fr;
    font-family: var(--font-sans);
  }

  nav {
    background-color: var(--surface-1);
    border-right: 1px solid var(--surface-3);
  }

  hr {
    margin: 0;
    height: 1px;
  }

  h1.title {
    font-size: var(--font-size-3);
    font-weight: 600;
    padding: var(--size-4);
    margin: 0;
    color: var(--gray-2);
  }

  a.github-link {
    display: block;
    padding: 0 var(--size-4) var(--size-2);
    margin: 0;
  }

  h2.category-title {
    font-size: var(--font-size-2);
    font-weight: 700;
    padding: var(--size-2) var(--size-4);
    margin-top: var(--size-4);
  }

  main {
    background-color: var(--gray-11);
    display: flex;
    justify-content: center;
    align-items: center;
    flex-direction: column;
    height: 100vh;
  }

  ul.nav-list {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  li.nav-item {
    padding: var(--size-1) var(--size-4);
    font-size: var(--font-size-1);
  }

  li.nav-item a {
    color: var(--gray-5);
    text-decoration: none;
    transition: all 0.2s ease-in-out;
  }

  li.nav-item a:visited,
  li.nav-item a:active {
    color: var(--gray-6);
  }

  li.nav-item a:hover {
    color: var(--gray-3);
  }

  li.nav-item-active a {
    color: var(--lime-5);
    text-decoration: none;
    transition: all 0.2s ease-in-out;
  }

  li.nav-item-active a:visited,
  li.nav-item-active a:active {
    color: var(--lime-6);
  }

  li.nav-item-active a:hover {
    color: var(--lime-3);
  }
</style>

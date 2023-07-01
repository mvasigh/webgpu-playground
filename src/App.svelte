<script lang="ts">
  import Router, { link, location } from "svelte-spa-router";
  import { ROUTES } from "./routes";
</script>

<div class="root">
  <nav>
    <h1 class="title">WebGPU</h1>
    <ul class="nav-list">
      {#each ROUTES as { href, label }}
        <li class="nav-item" class:nav-item-active={$location === href}>
          <a use:link {href}>
            {label}
          </a>
        </li>
      {/each}
    </ul>
  </nav>

  <main>
    <Router
      routes={ROUTES.reduce((dict, { href, component }) => {
        dict[href] = component;
        return dict;
      }, {})}
    />
  </main>
</div>

<style>
  .root {
    display: grid;
    grid-template-columns: 300px 1fr;
  }

  nav {
    background-color: var(--gray-11);
    border-right: 1px solid var(--gray-7);
  }

  h1.title {
    font-size: var(--size-6);
    font-weight: 600;
    padding: var(--size-4);
    margin: 0;
    color: var(--gray-5);
  }

  main {
    background-color: var(--gray-12);
    display: flex;
    justify-content: center;
    align-items: center;
    height: 100vh;
  }

  ul.nav-list {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  li.nav-item {
    padding: var(--size-1) var(--size-4);
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
    color: var(--gray-1);
  }

  li.nav-item-active a {
    color: var(--yellow-5);
    text-decoration: none;
    transition: all 0.2s ease-in-out;
  }

  li.nav-item-active a:visited,
  li.nav-item-active a:active {
    color: var(--yellow-6);
  }

  li.nav-item-active a:hover {
    color: var(--yellow-3);
  }
</style>

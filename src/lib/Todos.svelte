<script>
  import { onMount } from 'svelte';
  import { supabase } from './supabaseClient';

  let todos = $state([]);
  let loading = $state(true);
  let error = $state(null);

  onMount(async () => {
    try {
      const { data, error: err } = await supabase
        .from('todos')
        .select('*');
      
      if (err) throw err;
      todos = data;
    } catch (e) {
      error = e.message;
    } finally {
      loading = false;
    }
  });
</script>

<div class="p-4">
  <h2 class="text-2xl font-bold mb-4 text-white">Todos</h2>

  {#if loading}
    <p class="text-slate-400">Loading todos...</p>
  {:else if error}
    <p class="text-red-400">Error: {error}</p>
  {:else}
    <ul class="space-y-2">
      {#each todos as todo}
        <li class="bg-slate-800 p-3 rounded-lg border border-slate-700 text-white">
          {todo.name}
        </li>
      {/each}
      {#if todos.length === 0}
        <li class="text-slate-500 italic">No todos found.</li>
      {/if}
    </ul>
  {/if}
</div>

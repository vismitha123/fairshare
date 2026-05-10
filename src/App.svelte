<script>
  import { onMount } from 'svelte'
  import { supabase } from './lib/supabaseClient'
  import Auth from './lib/Auth.svelte'
  import Dashboard from './lib/Dashboard.svelte'
  import { LogOut } from 'lucide-svelte'

  let session = $state(null)
  let user = $state(null)

  onMount(() => {
    supabase.auth.getSession().then(({ data: { session: s } }) => {
      session = s
      user = s?.user
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, s) => {
      session = s
      user = s?.user
    })

    return () => subscription.unsubscribe()
  })

  async function handleSignOut() {
    await supabase.auth.signOut()
  }
</script>

<nav class="nav">
  <div class="container nav-content">
    <a href="/" class="logo">FairShare</a>
    {#if session}
      <div style="display: flex; gap: 20px; align-items: center;">
        <span style="color: var(--text-muted); font-size: 0.9rem;">{user.email}</span>
        <button onclick={handleSignOut} style="display: flex; align-items: center; gap: 8px; background: none; color: var(--text-muted);">
          <LogOut size={18} />
          Sign Out
        </button>
      </div>
    {/if}
  </div>
</nav>

<main class="container">
  {#if !session}
    <Auth />
  {:else}
    <Dashboard {user} />
  {/if}
</main>

<style>
  h1 {
    font-size: 2rem;
    font-weight: 800;
  }
</style>

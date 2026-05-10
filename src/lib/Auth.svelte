<script>
  import { supabase } from './supabaseClient'
  let loading = $state(false)
  let email = $state('')
  let password = $state('')
  let mode = $state('signin') // 'signin' or 'signup'

  let errorMessage = $state('')

  async function handleAuth(e) {
    e.preventDefault()
    loading = true
    errorMessage = ''
    try {
      if (mode === 'signup') {
        const { error } = await supabase.auth.signUp({ email, password })
        if (error) throw error
        alert('Check your email for the confirmation link!')
      } else {
        const { error } = await supabase.auth.signInWithPassword({ email, password })
        if (error) throw error
      }
    } catch (error) {
      errorMessage = error.message || 'An unexpected error occurred'
    } finally {
      loading = false
    }
  }
</script>

<div class="card animate-fade" style="max-width: 400px; margin: 60px auto;">
  <h2 style="margin-bottom: 24px; text-align: center;">
    {mode === 'signin' ? 'Welcome Back' : 'Create Account'}
  </h2>
  
  {#if errorMessage}
    <div style="background: #fff5f5; color: var(--error); padding: 12px; border-radius: var(--radius); margin-bottom: 20px; font-size: 0.9rem; border: 1px solid #ffe3e3;">
      {errorMessage}
    </div>
  {/if}
  
  <form onsubmit={handleAuth}>
    <div class="input-group">
      <label for="email">Email</label>
      <input type="email" id="email" bind:value={email} placeholder="you@example.com" required />
    </div>
    
    <div class="input-group">
      <label for="password">Password</label>
      <input type="password" id="password" bind:value={password} placeholder="••••••••" required />
    </div>

    <button type="submit" class="primary" style="width: 100%; margin-top: 10px;" disabled={loading}>
      {loading ? 'Processing...' : (mode === 'signin' ? 'Sign In' : 'Sign Up')}
    </button>
  </form>

  <div style="margin-top: 24px; text-align: center; color: var(--text-muted); font-size: 0.9rem;">
    {mode === 'signin' ? "Don't have an account?" : "Already have an account?"}
    <button 
      style="background: none; color: var(--primary); padding: 0; font-size: 0.9rem;"
      onclick={() => mode = mode === 'signin' ? 'signup' : 'signin'}
    >
      {mode === 'signin' ? 'Sign Up' : 'Sign In'}
    </button>
  </div>
</div>

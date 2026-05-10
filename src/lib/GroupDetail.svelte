<script>
  import { onMount } from 'svelte'
  import { supabase } from './supabaseClient'
  import { ArrowLeft, Plus, Trash2, UserPlus } from 'lucide-svelte'

  let { group, user, onBack } = $props()

  let expenses = $state([])
  let members = $state([])
  let loading = $state(true)
  let showAddExpense = $state(false)
  let showInviteModal = $state(false)
  let inviteEmail = $state('')
  let newExpense = $state({ description: '', amount: 0, payer_id: user.id })

  onMount(async () => {
    await Promise.all([fetchExpenses(), fetchMembers()])
  })

  async function fetchExpenses() {
    const { data, error } = await supabase
      .from('expenses')
      .select('*')
      .eq('group_id', group.id)
      .order('date', { ascending: false })
    
    if (!error) expenses = data
  }

  async function fetchMembers() {
    const { data, error } = await supabase
      .from('group_members')
      .select('*, profiles(*)')
      .eq('group_id', group.id)
    
    if (!error) members = data
  }

  async function addExpense() {
    if (!newExpense.description || !newExpense.amount) return

    const { data, error } = await supabase
      .from('expenses')
      .insert([{
        ...newExpense,
        group_id: group.id,
        created_by: user.id
      }])
      .select()

    if (error) {
      alert(error.message)
    } else {
      // For now, simplify: split equally among all members
      const expense = data[0]
      const splitAmount = expense.amount / members.length
      const splits = members.map(m => ({
        expense_id: expense.id,
        profile_id: m.profile_id,
        amount: splitAmount
      }))

      await supabase.from('expense_splits').insert(splits)
      
      newExpense = { description: '', amount: 0, payer_id: user.id }
      showAddExpense = false
      fetchExpenses()
    }
  }

  async function inviteMember() {
    if (!inviteEmail) return
    
    console.log('Inviting email:', inviteEmail)
    
    // Find user by email
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('id')
      .eq('email', inviteEmail)
      .maybeSingle()

    if (profileError) {
      console.error('Profile search error:', profileError)
      alert('Error searching for user: ' + profileError.message)
      return
    }

    if (!profile) {
      alert('User not found. They must have an account first (and their profile must be synced).')
      return
    }

    // Check if already a member
    const isAlreadyMember = members.some(m => m.profile_id === profile.id)
    if (isAlreadyMember) {
      alert('User is already in this group.')
      return
    }

    // Add to group
    const { error: joinError } = await supabase
      .from('group_members')
      .insert([{ group_id: group.id, profile_id: profile.id }])

    if (joinError) {
      alert(joinError.message)
    } else {
      inviteEmail = ''
      showInviteModal = false
      fetchMembers()
    }
  }
</script>

<div class="animate-fade">
  <button onclick={onBack} style="background: none; display: flex; align-items: center; gap: 8px; color: var(--text-muted); margin-bottom: 24px;">
    <ArrowLeft size={18} />
    Back to Dashboard
  </button>

  <header style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 32px;">
    <div>
      <h1>{group.name}</h1>
      <p style="color: var(--text-muted);">{group.description || 'Shared expenses'}</p>
    </div>
    <div style="display: flex; gap: 12px;">
      <button class="primary" style="display: flex; align-items: center; gap: 8px;" onclick={() => showAddExpense = true}>
        <Plus size={20} />
        Add Expense
      </button>
    </div>
  </header>

  <div style="display: grid; grid-template-columns: 2fr 1fr; gap: 32px;">
    <!-- Expenses List -->
    <section>
      <h2 style="margin-bottom: 20px; font-size: 1.2rem;">Recent Expenses</h2>
      {#if expenses.length === 0}
        <div class="card" style="text-align: center; padding: 40px; color: var(--text-muted);">
          No expenses yet.
        </div>
      {:else}
        <div style="display: grid; gap: 12px;">
          {#each expenses as expense}
            <div class="card" style="display: flex; justify-content: space-between; align-items: center; padding: 16px;">
              <div>
                <div style="font-weight: 600;">{expense.description}</div>
                <div style="font-size: 0.8rem; color: var(--text-muted);">{expense.date}</div>
              </div>
              <div style="text-align: right;">
                <div style="font-weight: 700; color: var(--primary);">${expense.amount}</div>
                <div style="font-size: 0.7rem; color: var(--text-muted);">Paid by you</div>
              </div>
            </div>
          {/each}
        </div>
      {/if}
    </section>

    <!-- Members List -->
    <aside>
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
        <h2 style="font-size: 1.2rem;">Members</h2>
        <button 
          style="background: none; color: var(--primary); font-size: 0.8rem; padding: 0;"
          onclick={() => showInviteModal = true}
        >
          + Invite
        </button>
      </div>
      <div class="card">
        <div style="display: grid; gap: 16px;">
          {#each members as member}
            <div style="display: flex; align-items: center; gap: 12px;">
              <div style="width: 32px; height: 32px; border-radius: 50%; background: var(--border); display: flex; align-items: center; justify-content: center; font-size: 0.8rem; font-weight: 600;">
                {member.profiles?.email?.charAt(0).toUpperCase()}
              </div>
              <div style="font-size: 0.9rem;">{member.profiles?.email === user.email ? 'You' : member.profiles?.email}</div>
            </div>
          {/each}
        </div>
      </div>
    </aside>
  </div>
</div>

{#if showAddExpense}
  <div class="modal-overlay" onclick={() => showAddExpense = false}>
    <div class="card modal-content" onclick={(e) => e.stopPropagation()}>
      <h3>Add Expense</h3>
      <div class="input-group" style="margin-top: 20px;">
        <label for="desc">Description</label>
        <input type="text" id="desc" bind:value={newExpense.description} placeholder="e.g. Dinner, Groceries" />
      </div>
      <div class="input-group">
        <label for="amount">Amount ($)</label>
        <input type="number" id="amount" bind:value={newExpense.amount} step="0.01" />
      </div>
      <div style="display: flex; gap: 12px; margin-top: 24px;">
        <button style="flex: 1; background: var(--border);" onclick={() => showAddExpense = false}>Cancel</button>
        <button class="primary" style="flex: 1;" onclick={addExpense}>Save Expense</button>
      </div>
    </div>
  </div>
{/if}

{#if showInviteModal}
  <div class="modal-overlay" onclick={() => showInviteModal = false}>
    <div class="card modal-content" onclick={(e) => e.stopPropagation()}>
      <h3>Invite Member</h3>
      <p style="font-size: 0.9rem; color: var(--text-muted); margin-top: 8px;">
        Add a friend by their email address.
      </p>
      <div class="input-group" style="margin-top: 20px;">
        <label for="inviteEmail">Email Address</label>
        <input type="email" id="inviteEmail" bind:value={inviteEmail} placeholder="friend@example.com" />
      </div>
      <div style="display: flex; gap: 12px; margin-top: 24px;">
        <button style="flex: 1; background: var(--border);" onclick={() => showInviteModal = false}>Cancel</button>
        <button class="primary" style="flex: 1;" onclick={inviteMember}>Invite</button>
      </div>
    </div>
  </div>
{/if}


<style>
  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.4);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
  }
  .modal-content {
    width: 100%;
    max-width: 400px;
  }
</style>

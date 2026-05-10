<script>
  import { onMount } from 'svelte'
  import { supabase } from './supabaseClient'
  import { Plus, Users, Wallet, ChevronRight } from 'lucide-svelte'
  import GroupDetail from './GroupDetail.svelte'

  let { user } = $props()

  let groups = $state([])
  let loading = $state(true)
  let showCreateModal = $state(false)
  let newGroupName = $state('')
  let selectedGroup = $state(null)

  onMount(async () => {
    await fetchGroups()
  })

  async function fetchGroups() {
    loading = true
    const { data, error } = await supabase
      .from('groups')
      .select(`
        *,
        group_members!inner(*)
      `)
    
    if (error) {
      console.error(error)
    } else {
      groups = data
    }
    loading = false
  }

  async function createGroup() {
    if (!newGroupName) return
    
    const { data, error } = await supabase
      .from('groups')
      .insert([{ name: newGroupName, created_by: user.id }])
      .select()

    if (error) {
      alert(error.message)
    } else {
      const group = data[0]
      // Add creator as member
      await supabase.from('group_members').insert([
        { group_id: group.id, profile_id: user.id, role: 'admin' }
      ])
      
      newGroupName = ''
      showCreateModal = false
      fetchGroups()
    }
  }
</script>

{#if selectedGroup}
  <GroupDetail group={selectedGroup} {user} onBack={() => { selectedGroup = null; fetchGroups(); }} />
{:else}
  <div class="dashboard animate-fade" style="margin-top: 40px;">
    <header style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 32px;">
      <h1>Dashboard</h1>
      <button class="primary" style="display: flex; align-items: center; gap: 8px;" onclick={() => showCreateModal = true}>
        <Plus size={20} />
        New Group
      </button>
    </header>

    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 24px;">
      <!-- Summary Cards (Placeholders for now) -->
      <div class="card" style="border-left: 4px solid var(--primary);">
        <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 16px; color: var(--text-muted);">
          <Wallet size={20} />
          <span style="font-weight: 600;">Total Balance</span>
        </div>
        <div style="font-size: 2rem; font-weight: 800; color: var(--primary);">$0.00</div>
      </div>

      <div class="card" style="border-left: 4px solid var(--error);">
        <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 16px; color: var(--text-muted);">
          <Users size={20} />
          <span style="font-weight: 600;">You Owe</span>
        </div>
        <div style="font-size: 2rem; font-weight: 800; color: var(--error);">$0.00</div>
      </div>

      <div class="card" style="border-left: 4px solid var(--success);">
        <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 16px; color: var(--text-muted);">
          <Users size={20} />
          <span style="font-weight: 600;">You are Owed</span>
        </div>
        <div style="font-size: 2rem; font-weight: 800; color: var(--success);">$0.00</div>
      </div>
    </div>

    <div style="margin-top: 48px;">
      <h2 style="margin-bottom: 24px;">Your Groups</h2>
      
      {#if loading}
        <p>Loading groups...</p>
      {:else if groups.length === 0}
        <div class="card" style="text-align: center; padding: 60px; color: var(--text-muted);">
          <Users size={48} style="margin-bottom: 16px; opacity: 0.3;" />
          <p>You haven't joined any groups yet.</p>
          <button class="primary" style="margin-top: 24px;" onclick={() => showCreateModal = true}>Create your first group</button>
        </div>
      {:else}
        <div style="display: grid; gap: 16px;">
          {#each groups as group}
            <div class="card" style="display: flex; justify-content: space-between; align-items: center; padding: 16px 24px; cursor: pointer;" onclick={() => selectedGroup = group}>
              <div>
                <h3 style="font-size: 1.1rem;">{group.name}</h3>
                <p style="color: var(--text-muted); font-size: 0.9rem;">{group.description || 'No description'}</p>
              </div>
              <ChevronRight size={20} color="var(--text-muted)" />
            </div>
          {/each}
        </div>
      {/if}
    </div>
  </div>
{/if}

{#if showCreateModal}
  <div class="modal-overlay" onclick={() => showCreateModal = false}>
    <div class="card modal-content" onclick={(e) => e.stopPropagation()}>
      <h3>Create New Group</h3>
      <div class="input-group" style="margin-top: 20px;">
        <label for="groupName">Group Name</label>
        <input type="text" id="groupName" bind:value={newGroupName} placeholder="e.g. Apartment, Trip to Italy" />
      </div>
      <div style="display: flex; gap: 12px; margin-top: 24px;">
        <button style="flex: 1; background: var(--border);" onclick={() => showCreateModal = false}>Cancel</button>
        <button class="primary" style="flex: 1;" onclick={createGroup}>Create</button>
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
    animation: slideUp 0.3s ease-out;
  }
  @keyframes slideUp {
    from { transform: translateY(20px); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }
</style>

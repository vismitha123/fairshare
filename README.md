# FairShare - Splitwise Clone

A modern, premium expense sharing application built with Svelte and Supabase.

## Features
- **Secure Auth**: Login/Signup with Supabase Auth.
- **Group Management**: Create groups for different trips or shared living.
- **Expense Tracking**: Add expenses and split them automatically.
- **Premium Design**: Clean, modern UI with smooth transitions.

## Setup Instructions

1.  **Supabase Setup**:
    - Create a new project on [Supabase](https://supabase.com).
    - Go to the **SQL Editor** and run the contents of `supabase_schema.sql` (found in the artifacts).
    - Go to **Project Settings > API** and copy your `URL` and `anon public` key.

2.  **Environment Variables**:
    - Create a `.env` file in the root directory.
    - Add your keys:
      ```
      VITE_SUPABASE_URL=your_project_url
      VITE_SUPABASE_ANON_KEY=your_anon_key
      ```

3.  **Install & Run**:
    ```bash
    npm install
    npm run dev
    ```

## Project Structure
- `src/lib/supabaseClient.js`: Supabase initialization.
- `src/lib/Auth.svelte`: Login and Signup screens.
- `src/lib/Dashboard.svelte`: Group overview and summary.
- `src/lib/GroupDetail.svelte`: Expense list and adding new costs.

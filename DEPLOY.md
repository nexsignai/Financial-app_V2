# Deploy Financial App (Flutter Web + Supabase)

## 1. Supabase setup (do this first)

1. Create a project at [supabase.com](https://supabase.com).
2. In **Settings → API** copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_ANON_KEY`
3. In **SQL Editor**, run the full **`supabase_schema.sql`** from this repo to create tables and RLS.

---

## 2. Fix 404 on refresh (SPA routing)

The repo is already set up so that refreshing or opening a deep link (e.g. `/dashboard`) does **not** return 404:

| Platform | Config | What it does |
|----------|--------|--------------|
| **Vercel** | **`vercel.json`** (project root) and **`web/vercel.json`** | Rewrites all paths `/(.*)` → `/index.html` |
| **Netlify** | **`web/_redirects`** (copied to `build/web`) and **`netlify.toml`** | Serves `index.html` for every route (200) |
| **Both** | **`web/index.html`** | `<base href="/">` so assets load correctly |

No extra steps needed—just deploy the **`build/web`** folder (see below).

---

## 3. Connect Supabase when you deploy

Supabase URL and anon key are **baked in at build time** via `--dart-define`. So you must build with:

- `SUPABASE_URL` = your project URL  
- `SUPABASE_ANON_KEY` = your anon key  

Use the **build scripts** (they read these from the environment), or run `flutter build web` with the defines yourself.

---

## 4. Build for production (with Supabase)

From the **project root** (`financial_app/`):

**Linux / macOS (Git Bash):**

```bash
export SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key-here"
./scripts/build_web.sh
```

**Windows (PowerShell):**

```powershell
$env:SUPABASE_URL = "https://YOUR_PROJECT_REF.supabase.co"
$env:SUPABASE_ANON_KEY = "your-anon-key-here"
.\scripts\build_web.ps1
```

**One-liner without script:**

```bash
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Output is in **`build/web/`**. That folder contains `index.html`, `vercel.json` (or `_redirects` for Netlify), and all assets—ready to deploy.

---

## 5. Deploy to Vercel

### Option A: Deploy the built folder (recommended)

1. Build with Supabase (step 4 above).  
2. Deploy **`build/web`**:
   - **CLI:** Install Vercel CLI, then from repo root:
     ```bash
     cd financial_app/build/web && vercel --prod
     ```
   - **Dashboard:** **Add New Project** → **Import** your repo → set **Root Directory** to `financial_app` → then either:
     - **Build:** Build Command = `./scripts/build_web.sh` (and in **Environment Variables** add `SUPABASE_URL` and `SUPABASE_ANON_KEY`). **Note:** Vercel’s default image does **not** include Flutter, so this only works if you use a custom build image or run the build elsewhere (e.g. GitHub Actions) and deploy the artifact, **or**
     - **No build on Vercel:** Build locally (step 4), then **Deploy** by uploading the **`build/web`** folder (drag & drop), or push `build/web` to a branch and point Vercel to that branch with **Build Command** left empty and **Output Directory** = `build/web` (only works if you commit `build/web`).

3. **Environment variables (if building on Vercel):** In project **Settings → Environment Variables**, add:
   - `SUPABASE_URL` = your Supabase project URL  
   - `SUPABASE_ANON_KEY` = your anon key  

4. **Output directory:** For any build that runs on Vercel, set **Output Directory** to **`build/web`**.  
   The root **`vercel.json`** (rewrite to `/index.html`) is applied automatically, so 404 on refresh is fixed.

### Option B: Build locally, then deploy static files

1. Run step 4 (build with Supabase).  
2. In Vercel: **Add New** → **Project** → **Import** your repo.  
3. Set **Root Directory** to `financial_app`.  
4. **Build Command:** e.g. `echo "Build done locally"` or leave blank if you’ll upload.  
5. **Output Directory:** `build/web`.  
6. If you’re not building on Vercel: build locally, then use **Vercel CLI** from `financial_app/build/web`: `vercel --prod`. Or use **Deploy** → upload the `build/web` folder.

Result: App runs with Supabase connected, and refresh/deep links work (no 404).

---

## 6. Deploy to Netlify

### Option A: Deploy the built folder (recommended)

1. Build with Supabase (step 4 above).  
2. Deploy **`build/web`**:
   - **CLI:** `netlify deploy --dir=financial_app/build/web --prod`  
   - **Dashboard:** **Add new site** → **Deploy manually** → drag and drop the **`build/web`** folder.  
3. **Environment variables (if you run build on Netlify):** **Site settings → Environment variables** → add `SUPABASE_URL` and `SUPABASE_ANON_KEY`.  
4. **Publish directory:** If you connect the repo and let Netlify build, set **Publish directory** to **`build/web`** (or use the existing **`netlify.toml`**, which already sets `publish = "build/web"` and the SPA redirect).

The **`web/_redirects`** file is copied into `build/web` by `flutter build web`, and **`netlify.toml`** also defines the SPA redirect, so 404 on refresh is fixed.

### Option B: Build locally, then deploy

1. Run step 4 (build with Supabase).  
2. **Netlify → Deploy manually** → select the **`build/web`** folder.  
3. Or connect repo, set **Build command** to your script (e.g. `./scripts/build_web.sh`) and **Publish directory** to `build/web`; Netlify’s default image does **not** include Flutter, so you may need to build locally and deploy the folder, or use a build image that has Flutter.

Result: App runs with Supabase connected, and refresh/deep links work (no 404).

---

## 7. Deploy from Git (optional: GitHub Actions → Vercel)

If your repo is **financial_app** (or you put the workflow in your repo root and set the app path):

1. In GitHub: **Settings → Secrets and variables → Actions** → add:
   - `SUPABASE_URL` = your Supabase project URL  
   - `SUPABASE_ANON_KEY` = your anon key  
   - (Optional, for auto-deploy) `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` from [Vercel](https://vercel.com/account/tokens) and project settings.
2. Push to `main` (or run **Actions → Build and deploy to Vercel → Run workflow**). The workflow builds with Supabase and, if Vercel secrets are set, deploys **build/web** to Vercel (404 is fixed by **vercel.json** in that folder).

If your repo root is the **parent** of **financial_app**, copy **`.github/workflows/deploy-vercel.yml`** to **`<repo_root>/.github/workflows/`** and in that workflow set the default working directory to **financial_app** for the build steps, and **financial_app/build/web** for the Vercel deploy step.

---

## 8. Verify after deploy

- Open the deployed URL (and try a direct link like `yoursite.com/dashboard`).  
- **Refresh the page** → you should **not** get 404 (SPA rewrites/redirects in place).  
- Log in; add a remittance or exchange → **Cash Flow** and **Profit Breakdown** update.  
- If Supabase was set at build time, data persists; otherwise the app runs in-memory only—recheck `SUPABASE_URL` and `SUPABASE_ANON_KEY` when building.

---

## Summary

| Goal | What to do |
|------|------------|
| **No 404 on refresh** | Deploy the **`build/web`** folder; `vercel.json` (Vercel) and `_redirects` / `netlify.toml` (Netlify) are already set. |
| **Supabase connected** | Build with `SUPABASE_URL` and `SUPABASE_ANON_KEY` (scripts or `--dart-define`), then deploy that **`build/web`** output. |
| **Easiest path** | Build locally with `./scripts/build_web.sh` (or `.ps1`) after setting the two env vars, then deploy the **`build/web`** folder to Vercel or Netlify. |

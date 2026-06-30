# Play Grass Stains in Your Browser

This project auto-builds a web version on every push to `main` and hosts it on **GitHub Pages** — no Godot install required on your PC.

## One-time setup (~5 minutes)

### 1. Create a GitHub repo

1. Go to [github.com/new](https://github.com/new)
2. Name it `grass-stains` (or anything you like)
3. Leave it **empty** (no README/license — we already have files)
4. Click **Create repository**

### 2. Push this project

Open PowerShell in the project folder and run (replace `YOUR_USERNAME`):

```powershell
cd C:\Users\zseidl\grass-stains
git branch -M main
git add -A
git commit -m "Add Grass Stains vertical slice with web deploy"
git remote add origin https://github.com/YOUR_USERNAME/grass-stains.git
git push -u origin main
```

### 3. Enable GitHub Pages

1. Open your repo on GitHub
2. **Settings** → **Pages**
3. Under **Build and deployment**, set **Source** to **GitHub Actions**
4. Save (no branch picker needed)

### 4. Wait for the build

1. Open the **Actions** tab
2. Watch the **Deploy Web Build** workflow (first run takes ~3–5 min)
3. When it finishes green, go back to **Settings → Pages** for your live URL

Your game will be at:

```text
https://YOUR_USERNAME.github.io/grass-stains/
```

## Controls in the browser

| Device | Controls |
|---|---|
| **Phone / tablet** | Left side = move · Right side = camera · Pull Cord button |
| **Desktop** | WASD · Space · Hold right mouse button for camera |

**Tip:** On iPhone, open the link in **Safari** and rotate to landscape for the best experience.

## Re-deploy

Every `git push` to `main` rebuilds and updates the live site automatically.

## Troubleshooting

| Problem | Fix |
|---|---|
| Actions tab shows no workflow | Push to `main` branch; confirm `.github/workflows/deploy-web.yml` exists |
| Build fails on export | Open the failed run log; usually a shader or preset name mismatch |
| Blank page after deploy | Hard-refresh (Ctrl+F5) or wait 1–2 min for Pages CDN |
| Pages URL 404 | Confirm **Settings → Pages → Source** is **GitHub Actions**, not `gh-pages` branch |

## Local Godot still optional

You only need Godot on a machine that isn't blocked if you want to edit the game locally. Playing only requires the GitHub Pages link.

# Assets

Decal, image, and item texture PNGs extracted from the Havoc game dump.

## Regenerate

```bash
npm run extract-catalog   # item icons from dump/catalog/instances.jsonl
npm run download-missing  # all dump asset IDs, skip existing, gentler API pacing
npm run download-assets   # same but max API throughput (~100 req/min)
```

Progress is saved to `assets/decals/download_progress.json` so interrupted runs resume without re-fetching completed IDs.

Commit new PNGs under `assets/decals/` and push to GitHub so in-game icons load from the CDN.

Downloads use the Roblox Thumbnails API (batch=100, ~100 req/min cap, parallel CDN fetches, 429 backoff). Not every asset ID produces a thumbnail (sounds/meshes may fail).

## CDN

```
https://raw.githubusercontent.com/Cunzaki/July/refs/heads/main/assets/decals/{id}.png
```

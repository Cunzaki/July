# Assets

Decal and icon PNGs extracted from the Havoc game dump.

## Regenerate

```bash
npm run extract-catalog
npm run download-missing
```

Commit new PNGs under `assets/decals/` and push to GitHub so in-game icons load from the CDN.

Downloads use the Roblox Thumbnails API with batching and delays to avoid rate limits.

## CDN

```
https://raw.githubusercontent.com/Cunzaki/July/refs/heads/main/assets/decals/{id}.png
```

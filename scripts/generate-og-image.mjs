// Generate OG image (1200x630) for social sharing.
// Run: node scripts/generate-og-image.mjs

import sharp from 'sharp';

const WIDTH = 1200;
const HEIGHT = 630;

const svg = `
<svg width="${WIDTH}" height="${HEIGHT}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#0a0a0a"/>
      <stop offset="100%" stop-color="#0d1f33"/>
    </linearGradient>
    <linearGradient id="accent" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#5b9bf5"/>
      <stop offset="100%" stop-color="#b8d4ff"/>
    </linearGradient>
  </defs>

  <!-- Background -->
  <rect width="${WIDTH}" height="${HEIGHT}" fill="url(#bg)"/>

  <!-- Accent line at top -->
  <rect x="0" y="0" width="${WIDTH}" height="4" fill="url(#accent)"/>

  <!-- Grid dots pattern -->
  ${Array.from({ length: 20 }, (_, i) =>
    Array.from({ length: 10 }, (_, j) =>
      `<circle cx="${60 + i * 60}" cy="${60 + j * 60}" r="1" fill="#1a1a1a"/>`
    ).join('')
  ).join('')}

  <!-- Title -->
  <text x="100" y="260" font-family="monospace"
        font-size="80" font-weight="700" fill="#e8e8e8"
        letter-spacing="-2">AgentsView</text>

  <!-- Tagline -->
  <text x="100" y="330" font-family="monospace"
        font-size="26" fill="#888888">
    Browse, search, and analyze your AI coding sessions
  </text>

  <!-- Feature pills -->
  <rect x="100" y="380" width="160" height="40" rx="4"
        fill="none" stroke="#333333" stroke-width="1"/>
  <text x="180" y="406" font-family="monospace"
        font-size="16" fill="#5b9bf5" text-anchor="middle"
        >13 agents</text>

  <rect x="280" y="380" width="160" height="40" rx="4"
        fill="none" stroke="#333333" stroke-width="1"/>
  <text x="360" y="406" font-family="monospace"
        font-size="16" fill="#5b9bf5" text-anchor="middle"
        >local-first</text>

  <rect x="460" y="380" width="160" height="40" rx="4"
        fill="none" stroke="#333333" stroke-width="1"/>
  <text x="540" y="406" font-family="monospace"
        font-size="16" fill="#5b9bf5" text-anchor="middle"
        >full-text search</text>

  <rect x="640" y="380" width="160" height="40" rx="4"
        fill="none" stroke="#333333" stroke-width="1"/>
  <text x="720" y="406" font-family="monospace"
        font-size="16" fill="#5b9bf5" text-anchor="middle"
        >live sync</text>

  <!-- URL -->
  <text x="100" y="560" font-family="monospace"
        font-size="22" fill="#555555">agentsview.io</text>
</svg>`;

await sharp(Buffer.from(svg))
  .png()
  .toFile(new URL('../public/og-image.png', import.meta.url).pathname);

console.log('Created public/og-image.png');

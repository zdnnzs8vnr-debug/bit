# GUSTAVOEURO — Portale Dark-Web / Hacker

Sito **single-page** per il business GUSTAVOEURO: banconote Euro Grade AAA+
e trasferimenti PayPal P2P anonimi. Estetica dark-web/hacker, nessun build step:
apri `index.html` e funziona.

**Tagline:** DAL DARK WEB AL TUO PORTAFOGLIO · EST. 2022

---

## Stack

| Livello | Scelta |
|---|---|
| UI | React 18 + ReactDOM 18 via CDN (unpkg, fallback jsdelivr) |
| Compilazione | `@babel/standalone@7.25.6` (`type="text/babel"`) |
| CSS | Tailwind CDN + design system custom (`.bgfx`, palette mista) |
| Router | hash router scritto a mano (`#/rotta`) |
| Font | Space Grotesk + JetBrains Mono (Google Fonts) |
| Stato | Context (lingua, carrello) + `localStorage` / `sessionStorage` |
| Build | **nessuno** |

---

## File

### Principali
| File | Ruolo |
|---|---|
| `index.html` | App completa (tutte le rotte, 5 lingue, gate, checkout) |
| `_headers` | Header sicurezza + cache (Netlify / Cloudflare Pages) |
| `.htaccess` | Hardening Apache + SPA fallback |
| `404.html` | Pagina errore a sé stante |
| `.nojekyll` | Disattiva Jekyll su GitHub Pages |
| `robots.txt` | Regole crawler + sitemap |

### Protezione / supporto
| File | Ruolo |
|---|---|
| `_redirects` | HTTPS + www→non-www + SPA fallback |
| `nginx.conf` | Server VPS TLS 1.2/1.3, header, rate limit |
| `netlify.toml` | Header + redirect Netlify |
| `vercel.json` | Header + rewrites Vercel |
| `Caddyfile` | Caddy v2 con TLS automatico |
| `firewall.conf` | Zone nginx, bad-bot map, metodo/probe filter |
| `ipset-block.sh` | Ban kernel-level via ipset + iptables |
| `sitemap.xml` | Tutte le rotte hash |
| `.well-known/security.txt` | RFC 9116 |
| `humans.txt` | Info team/stack |
| `manifest.webmanifest` | PWA, shortcut |
| `sw.js` | Service worker (network-first nav, cache-first asset) |

---

## File da aggiungere tu (accanto a `index.html`)

| File | Cosa |
|---|---|
| `note10.png` | Foto banconota 10 EUR (usata nella sezione "SU RICHIESTA") |
| `qr-sol.png` | QR wallet SOL |
| `qr-btc.png` | QR wallet BTC |
| `qr-ltc.png` | QR wallet LTC |
| `icon-192.png`, `icon-512.png` | Icone PWA |

Tutti hanno fallback automatico: se mancano, il sito non si rompe
(immagini → fallback remoti, QR → `api.qrserver.com`).

---

## Personalizzare il blocco PHOTO (10 secondi)

In cima allo script dentro `index.html` c'è **un unico blocco**:

```js
const PHOTO = {
  eur10:{ main:'note10.png', ... },
  eur20:{ main:'...IMG-4949.jpg', gallery:[ ... ] },
  eur50:{ main:'...IMG-4956.jpg', gallery:[ ... ] },
  qr:{ SOL:'qr-sol.png', BTC:'qr-btc.png', LTC:'qr-ltc.png' },
  fallbacks:[ ... ]
};

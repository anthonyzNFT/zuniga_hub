[README.md](https://github.com/user-attachments/files/33133876/README.md)
# Zuniga hub

Static family app on GitHub Pages, backed by Supabase (Google / email-link sign-in).

## Deploy
Upload this folder to a GitHub repo and turn on Pages from the main branch, root.
Open the Pages URL in Safari on an iPhone. Share, Add to Home Screen, Add. Then open it from the icon and sign in there.

## Files
- `index.html` — the whole app: door, splash, setup, feed, notes, events, profile, settings
- `manifest.json` — install metadata
- `sw.js` — service worker; keeps the app shell and fonts available offline (family data is never cached)
- `icon-180.png` — home screen icon (you add this)
- `icon-512.png` — door mark (you add this)
- `zuniga-hub-schema.sql` — tables
- `zuniga-hub-security.sql` — who is allowed to read and write (review before running)

## Notes
- Notes are built from real data: replies to your posts, asks, invites, RSVPs to your events, and reminders. There is no push yet.
- The Supabase key in `index.html` is a publishable key. It is meant to be public, which is why the rules in `zuniga-hub-security.sql` matter.
- Event banners are stored in the `banner_url` column as small compressed images and are fetched only when you open an event.
- Location search sends what you type to photon.komoot.io (OpenStreetMap data).

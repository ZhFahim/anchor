<div align="center">

<img src="https://raw.githubusercontent.com/zhfahim/anchor/main/web/public/icons/anchor_icon.png" alt="Anchor" width="120" height="120">

# Anchor

**An offline first, self hostable note taking application**

[![Version](https://img.shields.io/github/v/release/zhfahim/anchor?label=version)](https://github.com/zhfahim/anchor/releases)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED.svg?logo=docker)](https://github.com/zhfahim/anchor)

Anchor focuses on speed, privacy, simplicity, and reliability across mobile and web. Notes are stored locally, editable offline, and synced across devices when online.

</div>


## Features

- **Rich Text Editor** - Create and edit notes with powerful formatting (bold, italic, underline, headings, lists, checkboxes)
- **Tags System** - Organize notes with custom tags and colors
- **Note Backgrounds** - Customize notes with solid colors and patterns
- **Pin Notes** - Pin important notes for quick access
- **Archive Notes** - Archive notes for later reference
- **Search** - Search notes locally by title or content
- **Trash** - Soft delete notes with recovery period
- **Offline-First** - All edits work offline with local storage
- **Automatic Sync** - Sync changes across devices when online
- **Dark Mode** - Beautiful dark and light themes
- **Admin Panel** - User management, registration control, and system statistics


## Screenshots

### Web App

<div align="center">
  <img src="https://raw.githubusercontent.com/zhfahim/anchor/main/.github/assets/screenshot-web-light.png" alt="Web Light Mode" width="45%">
  <img src="https://raw.githubusercontent.com/zhfahim/anchor/main/.github/assets/screenshot-web-dark.png" alt="Web Dark Mode" width="45%">
</div>

### Mobile App

<div align="center">
  <img src="https://raw.githubusercontent.com/zhfahim/anchor/main/.github/assets/screenshot-mobile-light.jpg" alt="Mobile Light Mode" width="20%">
  <img src="https://raw.githubusercontent.com/zhfahim/anchor/main/.github/assets/screenshot-mobile-dark.jpg" alt="Mobile Dark Mode" width="20%">
</div>


## Self Hosting With Docker

### Option 1: Using Pre-built Image (Recommended)

1. **Create a `docker-compose.yml` file:**
   ```yaml
   services:
     anchor:
       image: ghcr.io/zhfahim/anchor:latest
       container_name: anchor
       restart: unless-stopped
       ports:
         - "3000:3000"
       volumes:
         - anchor_data:/data

   volumes:
     anchor_data:
   ```

2. **(Optional) Configure environment:**
   Add environment variables to the `environment` section. Most users can skip this step - defaults work out of the box.

   Available options:
   | Variable | Default | Description |
   |----------|---------|-------------|
   | `JWT_SECRET` | (auto-generated) | Auth token secret (persisted in `/data`) |
   | `PG_HOST` | (empty) | External Postgres host (leave empty for embedded) |
   | `PG_PORT` | `5432` | Postgres port |
   | `PG_USER` | `anchor` | Postgres username |
   | `PG_PASSWORD` | `password` | Postgres password |
   | `PG_DATABASE` | `anchor` | Database name |
   | `USER_SIGNUP` | (not set) | Sign up mode: `disabled`, `enabled`, or `review`. If not set, admins can control it via the admin panel |

3. **Start the container:**
   ```bash
   docker compose up -d
   ```

4. **Access the app:**
   Open http://localhost:3000

### Option 2: Building from Source

If you want to build from source or customize the image:

1. **Clone the project:**
   ```bash
   git clone https://github.com/zhfahim/anchor.git
   cd anchor
   ```

2. **Start the container:**
   ```bash
   docker compose up -d
   ```

   The `docker-compose.yml` file will build the image from source automatically.


## Mobile App

Download the Android mobile app.

1. **Visit the releases page:**
   Go to [GitHub Releases](https://github.com/zhfahim/anchor/releases).

2. **Download the latest release:**
   Multiple APK files are available:
   - **Universal APK** (`anchor-{version}.apk`) - Recommended for most users, works on all devices
   - **Architecture-specific APKs** - Smaller file sizes for specific CPU architectures


## Roadmap

Future planned features:

- Media attachments (images, PDFs, recordings)
- Reminders and notifications
- End-to-end encryption
- Real-time collaboration
- Multi-user shared notes


## Tech Stack

- **Backend**: Nest.js, PostgreSQL, Prisma
- **Mobile**: Flutter
- **Web**: Next.js, TypeScript


## Contributing

1. Fork the repository
2. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature
   ```
3. Make your changes
4. Ensure builds pass:
   - Web: `cd web && pnpm build`
   - Server: `cd server && pnpm build`
5. Commit changes:
   ```bash
   git commit -m "Describe your change"
   ```
6. Push and create a Pull Request


## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL v3) - see the [LICENSE](LICENSE) file for details.
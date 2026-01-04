# Anchor

Anchor is an offline-first, self-hostable note-taking application. It focuses on speed, privacy, simplicity, and reliability across mobile and web. Notes are stored locally, editable offline, and synced across devices when online.

This repository includes:
- **Mobile App** (Flutter)
- **Web App** (Next.js)
- **Backend Server** (Nest.js)
- **Docker Compose** for self-hosting


## Features

- **Rich Text Editor** - Create and edit notes with powerful formatting (bold, italic, underline, headings, lists, checkboxes)
- **Tags System** - Organize notes with custom tags and colors
- **Note Backgrounds** - Customize notes with solid colors and patterns
- **Pin Notes** - Pin important notes for quick access
- **Search** - Search notes locally by title or content
- **Trash** - Soft delete notes with recovery period
- **Offline-First** - All edits work offline with local storage
- **Automatic Sync** - Sync changes across devices when online
- **Dark Mode** - Beautiful dark and light themes


## Tech Stack

### Mobile (Flutter)
- Flutter (latest stable)
- Riverpod (state management and DI)
- Drift (local offline database)
- Dio (network client)
- json_serializable (data models)
- connectivity_plus (online/offline detection)
- GoRouter (navigation)
- Flutter Quill (rich text editor)

### Web (Next.js)
- Next.js 16 (App Router)
- Tailwind CSS (styling)
- shadcn/ui (UI components, Radix UI primitives)
- Zustand (state management)
- TanStack Query (data fetching)
- ky (network client)
- react-quill-new (rich text editor)
- Lucide React (icons)
- date-fns (date formatting)

### Backend (Nest.js)
- Nest.js (modular server framework)
- Prisma (ORM)
- PostgreSQL (database)
- JWT authentication
- REST API endpoints
- Class Validator (input validation)
- Helmet and rate limiting (security)


## Self-Hosting With Docker

1. **Clone the project:**
   ```bash
   git clone https://github.com/zhfahim/anchor.git
   cd anchor
   ```

2. **(Optional) Configure environment:**
   Copy `.env.example` to `.env` and adjust values. Most users can skip this step - defaults work out of the box.

   Available options:
   | Variable | Default | Description |
   |----------|---------|-------------|
   | `JWT_SECRET` | (auto-generated) | Auth token secret (persisted in `/data`) |
   | `PG_HOST` | (empty) | External Postgres host (leave empty for embedded) |
   | `PG_PORT` | `5432` | Postgres port |
   | `PG_USER` | `anchor` | Postgres username |
   | `PG_PASSWORD` | `password` | Postgres password |
   | `PG_DATABASE` | `anchor` | Database name |

3. **Start the container:**
   ```bash
   docker compose up -d
   ```

4. **Access the app:**
   Open http://localhost:3000


## Roadmap

Future planned features:

- Media attachments (images, PDFs, recordings)
- Reminders and notifications
- End-to-end encryption
- Real-time collaboration
- Multi-user shared notes


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

Anchor will be released under an open-source license.  
License information will be added soon.

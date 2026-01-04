# Anchor Server

Nest.js backend for Anchor application.

## Prerequisites

- Node.js
- Docker & Docker Compose

## Setup

1.  Install dependencies:
    ```bash
    pnpm install
    ```

2.  Set up environment variables:
    Copy `.env.example` to `.env` (if it exists) or ensure `.env` has:
    ```env
    DATABASE_URL="postgresql://anchor:password@localhost:5432/anchor?schema=public"
    JWT_SECRET="supersecretkey"
    PORT=3001
    ```

3.  Start Database:
    From the project root:
    ```bash
    docker compose -f ../docker-compose.dev.yml up -d db
    ```

4.  Generate Prisma Client:
    ```bash
    pnpm exec prisma generate
    ```

5.  Run Migrations:
    ```bash
    pnpm exec prisma migrate dev
    ```

## Running the app

```bash
# development
pnpm run start

# watch mode
pnpm run start:dev

# production mode
pnpm run start:prod
```

## Test

```bash
# unit tests
pnpm run test

# e2e tests
pnpm run test:e2e
```

## API Endpoints

### Auth
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login

### Notes
- `GET /api/notes` - Get all notes (supports `?search=term`)
- `POST /api/notes` - Create a note
- `GET /api/notes/:id` - Get a specific note
- `PATCH /api/notes/:id` - Update a note
- `DELETE /api/notes/:id` - Delete a note
- `POST /api/notes/sync` - Sync notes with client
- `PATCH /api/notes/:id/restore` - Restore a note from trash
- `DELETE /api/notes/:id/permanent` - Permanently delete a note

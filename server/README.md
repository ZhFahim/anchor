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
- `GET /api/auth/registration-mode` - Get current registration mode (public)
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login
- `POST /api/auth/refresh` - Refresh access token using refresh token
- `GET /api/auth/me` - Get current user
- `PATCH /api/auth/profile` - Update profile name
- `POST /api/auth/profile/image` - Upload profile image
- `DELETE /api/auth/profile/image` - Remove profile image
- `POST /api/auth/change-password` - Change password

### OIDC Authentication
- `GET /api/auth/oidc/config` - Get OIDC configuration (public)
- `GET /api/auth/oidc/initiate` - Initiate OIDC login flow (redirects to provider)
- `GET /api/auth/oidc/callback` - OIDC callback (handles provider redirect)
- `POST /api/auth/oidc/exchange` - Exchange one-time code for tokens (web)
- `POST /api/auth/oidc/exchange/mobile` - Exchange IdP access token for app tokens (mobile)

### Notes
- `GET /api/notes` - Get all notes (supports `?search=term` and `?tagId=id`)
- `GET /api/notes/trash` - Get all trashed notes
- `GET /api/notes/archive` - Get all archived notes
- `POST /api/notes` - Create a note
- `GET /api/notes/:id` - Get a specific note
- `PATCH /api/notes/:id` - Update a note
- `DELETE /api/notes/:id` - Delete a note (soft delete)
- `POST /api/notes/sync` - Sync notes with client
- `PATCH /api/notes/:id/restore` - Restore a note from trash
- `DELETE /api/notes/:id/permanent` - Permanently delete a note
- `POST /api/notes/bulk/delete` - Bulk delete notes
- `POST /api/notes/bulk/archive` - Bulk archive notes

### Note Sharing
- `POST /api/notes/:id/shares` - Share a note with a user
- `GET /api/notes/:id/shares` - Get all shares for a note
- `PATCH /api/notes/:id/shares/:shareId` - Update share permission
- `DELETE /api/notes/:id/shares/:shareId` - Revoke a share

### Tags
- `GET /api/tags` - Get all tags
- `POST /api/tags` - Create a tag
- `GET /api/tags/:id` - Get a specific tag
- `GET /api/tags/:id/notes` - Get all notes with a specific tag
- `PATCH /api/tags/:id` - Update a tag
- `DELETE /api/tags/:id` - Delete a tag
- `POST /api/tags/sync` - Sync tags with client

### Admin (requires admin privileges)
- `GET /api/admin/stats` - Get server statistics
- `GET /api/admin/settings/registration` - Get registration settings
- `PATCH /api/admin/settings/registration` - Update registration mode (disabled if locked by env)
- `GET /api/admin/settings/oidc` - Get OIDC settings
- `PATCH /api/admin/settings/oidc` - Update OIDC settings (disabled if locked by env)
- `GET /api/admin/users` - Get all users (supports `?skip=n` and `?take=n`)
- `GET /api/admin/users/pending` - Get pending users awaiting approval
- `POST /api/admin/users` - Create a new user
- `PATCH /api/admin/users/:id` - Update a user
- `DELETE /api/admin/users/:id` - Delete a user
- `POST /api/admin/users/:id/reset-password` - Reset a user's password
- `POST /api/admin/users/:id/approve` - Approve a pending user
- `POST /api/admin/users/:id/reject` - Reject and delete a pending user

### Health
- `GET /api/health` - Health check endpoint

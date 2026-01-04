# Anchor Web

A modern, feature-rich note-taking web application built with Next.js, React, and TypeScript. Anchor provides a clean and intuitive interface for creating, organizing, and managing notes with rich text editing, tags, backgrounds, and more.

## Features

- **Rich Text Editor** - Create and edit notes with a powerful Quill-based editor
- **Tags System** - Organize notes with custom tags and colors
- **Note Backgrounds** - Customize notes with solid colors and patterns
- **Pin Notes** - Pin important notes for quick access
- **Search** - Quickly find notes by title or content
- **Trash** - Soft delete notes with 30-day recovery period
- **Dark Mode** - Beautiful dark and light themes
- **Responsive Design** - Works seamlessly on desktop and mobile devices
- **Authentication** - Secure user authentication and session management

## Tech Stack

- **Framework**: [Next.js 16](https://nextjs.org/) (App Router)
- **Language**: [TypeScript](https://www.typescriptlang.org/)
- **Styling**: [Tailwind CSS](https://tailwindcss.com/)
- **UI Components**: [shadcn/ui](https://ui.shadcn.com/) (Radix UI primitives)
- **State Management**: [Zustand](https://zustand-demo.pmnd.rs/)
- **Data Fetching**: [TanStack Query](https://tanstack.com/query)
- **HTTP Client**: [ky](https://github.com/sindresorhus/ky)
- **Rich Text Editor**: [react-quill-new](https://github.com/zenoamaro/react-quill)
- **Icons**: [Lucide React](https://lucide.dev/)
- **Date Formatting**: [date-fns](https://date-fns.org/)

## Getting Started

### Prerequisites

- Node.js 18+ or Bun
- pnpm (recommended) or npm/yarn

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd anchor/web
```

2. Start the backend (required):
Ensure you have a database and backend running. From the project root:
```bash
docker compose -f docker-compose.dev.yml up -d
```

3. Install dependencies:
```bash
pnpm install
```

3. Set up environment variables:
```bash
cp .env.example .env.local
```

Edit `.env.local` and add your API URL:
```env
NEXT_PUBLIC_API_URL=http://localhost:3001
```

4. Run the development server:
```bash
pnpm dev
```

5. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Project Structure

```
web/
├── app/                     # Next.js App Router pages
│   ├── (app)/               # Authenticated routes
│   │   ├── notes/           # Notes pages
│   │   └── trash/           # Trash page
│   └── (auth)/              # Authentication routes
│       ├── login/
│       └── register/
│
├── components/              # Shared UI components
│   ├── layout/              # App layout (header, sidebar)
│   └── ui/                  # shadcn/ui primitives
│
├── features/                # Feature modules (self-contained)
│   ├── auth/                # Authentication
│   │   ├── components/      # AuthGuard, GuestGuard
│   │   ├── hooks/           # useAuth hook
│   │   ├── api.ts           # API calls
│   │   ├── types.ts         # TypeScript types
│   │   └── store.ts         # Zustand store
│   ├── notes/               # Notes feature
│   │   ├── components/      # NoteCard, RichTextEditor, etc.
│   │   ├── backgrounds/     # Background data & utils
│   │   ├── api.ts
│   │   ├── types.ts
│   │   └── quill.ts         # Editor utilities
│   └── tags/                # Tags feature
│       ├── components/      # TagSelector
│       ├── api.ts
│       └── types.ts
│
└── lib/                     # Shared utilities
    ├── api/                 # API client configuration
    └── utils.ts             # General utilities
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NEXT_PUBLIC_API_URL` | Backend API URL | `http://localhost:3001` |

## Development

### Adding a New Feature

1. Create a new folder in `features/[feature-name]/`
2. Add the following files:
   - `api.ts` - API calls
   - `types.ts` - TypeScript interfaces
   - `index.ts` - Public exports
3. Add `components/` folder for feature-specific UI
4. Add `store.ts` if state management is needed
5. Export everything through `index.ts`

## Contributing

1. Create a feature branch
2. Make your changes
3. Ensure the build passes: `pnpm build`
4. Run linting: `pnpm lint`
5. Submit a pull request
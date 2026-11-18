# Contributing to Anchor

Thanks for your interest in Anchor. This guide explains how to report problems, suggest ideas and send changes so that they can be reviewed quickly.

Every issue and pull request is read and reviewed by hand, so please make them easy to act on.

## Questions and help

For help with installing, configuring or using Anchor, ask on [Discord](https://discord.gg/sAfqjy8EYK). Issues are for bugs and feature requests.

## Reporting a bug

Use the [bug report form](https://github.com/ZhFahim/anchor/issues/new?template=bug_report.yml). A good report has:

- **One bug per issue.**
- **The versions** of the app and the server. Both are shown in Settings.
- **Exact steps to reproduce**, starting from a fresh screen. A bug that can't be reproduced can't be fixed.
- **Logs.** In the phone app open Settings, Logs, tap **•••** and choose **Save to a file**. For the server run `docker logs anchor --tail 200`. For the web app copy the errors from the browser console.
- **A screenshot or short recording** for anything you can see.

Search the [existing issues](https://github.com/ZhFahim/anchor/issues?q=is%3Aissue) first. If one already covers your bug, add your details there instead of opening a new one.

Security problems should not go in a public issue. See the [security policy](SECURITY.md).

## Suggesting a feature

Use the [feature request form](https://github.com/ZhFahim/anchor/issues/new?template=feature_request.yml). Describe the problem you want solved, not only the solution. Not every idea will fit Anchor, and that is fine: a clear request still helps shape what comes next.

## Sending a pull request

### Talk first

**Open an issue and wait for the maintainer to agree before you write a new feature or a large change.** Anchor has a design guide and decisions that are not all visible in the code, and a pull request that goes a different way may be closed even if the code is good. An agreed issue saves your time as well as the reviewer's.

You don't need an issue for typos, documentation fixes or small, clear bug fixes.

### Keep it small

- One pull request does one thing. Don't mix a fix with a refactor, formatting changes or a new feature.
- Big changes are hard to review. If a change touches many files, ask in the issue how to split it.
- Keep to the style of the code around your change.
- Phone app text goes in `mobile/lib/l10n/app_en.arb` with a description for translators, never as text in the code.

### Test it yourself

Before you open a pull request:

1. Run the checks for every part you changed (see [Checks](#checks)).
2. Run the app and try the change by hand on each platform it touches: web, Android, iPhone or the server.
3. For anything you can see, add before and after screenshots in light and dark mode.

Say in the pull request what you tested and how. "Tests pass" is not enough for a change people can see or use.

### Title

Pull request titles follow [Conventional Commits](https://www.conventionalcommits.org), because the release notes are built from them:

```
type(scope): what changed
```

- **type:** `feat`, `fix`, `perf`, `docs`, `refactor`, `test`, `chore`, `ci` or `build`.
- **scope:** `web`, `mobile` or `server`. Leave it out when a change covers more than one.

For example `fix(mobile): keep the cursor at the start of a line` or `feat(web): show note history`.

### Review

Reply to review comments yourself. If you can't make the requested changes, say so, and the maintainer can take over or close it. Pull requests with no reply for a few weeks may be closed.

## AI tools

You may use AI tools to help you write code, but **you are the author and you are responsible for the changes**. This applies to issues and pull requests alike.

- Review the changes yourself before you submit them, and make sure you understand what they do and why.
- Run and test the change yourself, as described above. An AI saying it works is not testing.
- Write the description in your own words, short and to the point. Remove anything that is not true for your change.
- Say in the pull request which tool you used and for what.
- Don't list an AI tool or agent as an author or co-author, in commits (for example a `Co-Authored-By` line) or in the pull request. Only people are credited.
- Answer review questions yourself, not by pasting AI output.
- Don't let an AI agent open issues or pull requests on its own.

Pull requests that look like unreviewed AI output will be closed without review. Signs of this are changes unrelated to the issue, code that calls things that don't exist, failing checks, a large feature nobody agreed to, or a description that doesn't match the code.

## Development

### Project layout

| Folder | What it is | Stack |
|--------|------------|-------|
| `server/` | API and sync | Nest.js, PostgreSQL, Prisma |
| `web/` | Web app | Next.js, TypeScript |
| `mobile/` | Android and iPhone app | Flutter |
| `design/` | Design tokens for the web app | W3C Design Tokens |

### Running it locally

The server, web app and database run with Docker:

```bash
cp .env.example .env
docker compose -f docker-compose.dev.yml up
```

The web app is at http://localhost:3000 and the API at http://localhost:3001. Both reload when you change a file.

To run the phone app, start the server above, then run `flutter run` in `mobile/` and sign in with your computer's address on port 3000.

### Checks

CI runs these on every pull request. Run them for each part you changed:

| Part | Commands |
|------|----------|
| Server | `cd server && pnpm install && pnpm exec prisma generate && pnpm check && pnpm test` |
| Web | `cd web && pnpm install && pnpm check && pnpm test && pnpm build` |
| Phone app | `cd mobile && flutter pub get && flutter analyze && flutter test` |

Fix lint and format problems with `pnpm check:fix` in `server/` or `web/`, and `dart format lib test` in `mobile/`.

### Pre-commit hook

A pre-commit hook in `.githooks/pre-commit` checks staged files in `server/` and `web/`. Running `pnpm install` in either folder turns it on. To turn it on by hand:

```bash
git config core.hooksPath .githooks
```

### Design tokens

The web app's colors, text sizes, spacing, corners, shadows and motion live in `design/tokens/`. `web/app/styles/tokens.css`, `web/app/styles/notes.css` and `web/lib/design/tokens.ts` are built from them, so change the tokens rather than those files. After changing a token, run this from the repository root (run `pnpm install` in `web/` first, because it reads icons from `web/node_modules`):

```bash
node design/build/build.mjs
```

CI runs it with `--check` and fails if the built files are out of date.

## License

By contributing, you agree that your contributions are licensed under the [GNU Affero General Public License v3.0](../LICENSE), the same license as Anchor.

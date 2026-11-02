/**
 * Sets a new password for any account, for whoever can run commands on the
 * server (in Docker: `docker exec -it anchor-plus reset-password <email>`). It
 * talks to the database directly, so it also works when no admin can sign in.
 *
 *   reset-password                     lists the accounts
 *   reset-password <email>             sets a generated password and prints it
 *   reset-password <email> --password  asks for the new password instead
 */
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import * as readline from 'readline';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../generated/prisma/client';
import { UserStatus } from '../generated/prisma/enums';
import { BCRYPT_SALT_ROUNDS } from '../auth/constants/auth.constants';

const MIN_PASSWORD_LENGTH = 8;

const USAGE = `Usage:
  reset-password                     list the accounts
  reset-password <email>             set a generated password and print it
  reset-password <email> --password  type the new password instead`;

// Same shape as the passwords the admin UI generates.
function generatePassword(): string {
  return crypto
    .randomBytes(12)
    .toString('base64')
    .replace(/[+/=]/g, '')
    .slice(0, 16);
}

// Reads one line without echoing it when attached to a terminal; piped input
// (`echo secret | reset-password me@x --password`) is read as is.
function readSecret(prompt: string): Promise<string> {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      terminal: process.stdin.isTTY,
    });
    if (process.stdin.isTTY) {
      const output = rl as unknown as { _writeToOutput: (s: string) => void };
      output._writeToOutput = (s: string) => {
        if (s.startsWith(prompt)) process.stdout.write(prompt);
      };
    }
    rl.question(prompt, (answer) => {
      rl.close();
      if (process.stdin.isTTY) process.stdout.write('\n');
      resolve(answer);
    });
  });
}

async function askPassword(): Promise<string> {
  const password = await readSecret('New password: ');
  if (password.length < MIN_PASSWORD_LENGTH) {
    throw new Error(
      `The password needs at least ${MIN_PASSWORD_LENGTH} characters.`,
    );
  }
  if (process.stdin.isTTY) {
    const repeated = await readSecret('Repeat it: ');
    if (repeated !== password) throw new Error('The passwords differ.');
  }
  return password;
}

async function listUsers(prisma: PrismaClient) {
  const users = await prisma.user.findMany({
    orderBy: { createdAt: 'asc' },
    select: { email: true, name: true, isAdmin: true, status: true },
  });
  if (users.length === 0) {
    console.log('There are no accounts yet.');
    return;
  }
  for (const user of users) {
    const notes = [
      user.isAdmin ? 'admin' : null,
      user.status !== UserStatus.active ? user.status : null,
    ].filter(Boolean);
    const suffix = notes.length ? `  [${notes.join(', ')}]` : '';
    console.log(`${user.email}  (${user.name})${suffix}`);
  }
}

async function resetPassword(
  prisma: PrismaClient,
  email: string,
  askForPassword: boolean,
) {
  const user = await prisma.user.findFirst({
    where: { email: { equals: email, mode: 'insensitive' } },
    select: { id: true, email: true, status: true, oidcSubject: true },
  });
  if (!user) {
    throw new Error(
      `No account with the email ${email}. Run reset-password without arguments to list them.`,
    );
  }

  const password = askForPassword ? await askPassword() : generatePassword();
  await prisma.user.update({
    where: { id: user.id },
    data: { password: await bcrypt.hash(password, BCRYPT_SALT_ROUNDS) },
  });

  console.log(`Password reset for ${user.email}.`);
  if (!askForPassword) console.log(`New password: ${password}`);
  if (user.status === UserStatus.pending) {
    console.log(
      'The account is still waiting for approval; approve it in the admin panel before signing in.',
    );
  }
  if (user.oidcSubject) {
    console.log(
      'The account is also linked to single sign-on, which keeps working.',
    );
  }
}

async function main() {
  const args = process.argv.slice(2);
  if (args.includes('-h') || args.includes('--help')) {
    console.log(USAGE);
    return;
  }
  const flags = args.filter((arg) => arg.startsWith('-'));
  const positional = args.filter((arg) => !arg.startsWith('-'));
  if (positional.length > 1 || flags.some((flag) => flag !== '--password')) {
    throw new Error(USAGE);
  }
  const askForPassword = flags.length > 0;
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is not set.');
  }

  const prisma = new PrismaClient({
    adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }),
  });
  try {
    if (positional.length === 0) {
      await listUsers(prisma);
    } else {
      await resetPassword(prisma, positional[0], askForPassword);
    }
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});

import { Prisma } from '../generated/prisma/client';
import type { PrismaService } from '../prisma/prisma.service';

export async function bumpSyncVersion(
  tx: PrismaService | Prisma.TransactionClient,
): Promise<bigint> {
  const rows = await tx.$queryRaw<Array<{ nextval: bigint }>>`
    SELECT nextval('sync_version_seq') AS nextval
  `;
  return rows[0].nextval;
}

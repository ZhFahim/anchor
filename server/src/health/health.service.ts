import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

// A stopped Postgres can leave a new connection waiting with no end.
const DATABASE_TIMEOUT_MS = 5000;

@Injectable()
export class HealthService {
  constructor(private readonly prisma: PrismaService) {}

  /** Whether the database answers a query in time. */
  async isDatabaseUp(): Promise<boolean> {
    let timer: NodeJS.Timeout | undefined;
    const timeout = new Promise<false>((resolve) => {
      timer = setTimeout(() => resolve(false), DATABASE_TIMEOUT_MS);
    });
    const query = this.prisma.$queryRaw`SELECT 1`.then(
      () => true,
      () => false,
    );
    try {
      return await Promise.race([query, timeout]);
    } finally {
      clearTimeout(timer);
    }
  }
}

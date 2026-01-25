import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { USER_SELECT_FIELDS } from '../notes/constants/notes.constants';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async searchUsers(searchQuery: string, currentUserId: string) {
    if (!searchQuery || searchQuery.trim().length < 2) {
      return [];
    }

    const query = searchQuery.trim();

    return this.prisma.user.findMany({
      where: {
        AND: [
          { id: { not: currentUserId } },
          { status: 'active' },
          { email: { equals: query, mode: 'insensitive' } },
        ],
      },
      select: USER_SELECT_FIELDS,
      take: 10,
      orderBy: { name: 'asc' },
    });
  }
}

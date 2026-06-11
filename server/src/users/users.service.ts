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
          {
            OR: [
              { email: { contains: query, mode: 'insensitive' } },
              { name: { contains: query, mode: 'insensitive' } },
            ],
          },
        ],
      },
      select: USER_SELECT_FIELDS,
      take: 10,
      orderBy: { name: 'asc' },
    });
  }

  async getRecentContacts(currentUserId: string) {
    const shares = await this.prisma.noteShare.findMany({
      where: {
        sharedByUserId: currentUserId,
        sharedWithUser: { status: 'active' },
      },
      distinct: ['sharedWithUserId'],
      orderBy: { updatedAt: 'desc' },
      take: 5,
      select: { sharedWithUser: { select: USER_SELECT_FIELDS } },
    });

    return shares.map((share) => share.sharedWithUser);
  }
}

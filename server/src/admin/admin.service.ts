import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SettingsService } from '../settings/settings.service';
import { OidcConfigService } from '../auth/oidc/oidc-config.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { NoteState } from 'src/generated/prisma/enums';
import { UserStatus } from 'src/generated/prisma/enums';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';

@Injectable()
export class AdminService {
  constructor(
    private prisma: PrismaService,
    private settingsService: SettingsService,
    private oidcConfigService: OidcConfigService,
  ) { }

  async getStats() {
    const [totalUsers, totalNotes, totalTags] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.note.count({
        where: {
          state: { not: NoteState.deleted },
        },
      }),
      this.prisma.tag.count(),
    ]);

    return {
      totalUsers,
      totalNotes,
      totalTags,
    };
  }

  async getRegistrationSettings() {
    return this.settingsService.getRegistrationSettings();
  }

  async updateRegistrationMode(mode: 'disabled' | 'enabled' | 'review') {
    await this.settingsService.setRegistrationMode(mode);
    return this.settingsService.getRegistrationSettings();
  }

  async findAllUsers(skip = 0, take = 50) {
    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          email: true,
          name: true,
          isAdmin: true,
          status: true,
          oidcSubject: true,
          createdAt: true,
          updatedAt: true,
          _count: {
            select: {
              notes: {
                where: {
                  state: { not: NoteState.deleted },
                },
              },
              tags: true,
            },
          },
        },
      }),
      this.prisma.user.count(),
    ]);

    const usersWithAuthMethod = users.map(({ oidcSubject, ...rest }) => ({
      ...rest,
      authMethod: oidcSubject ? ('oidc' as const) : ('local' as const),
    }));

    return {
      users: usersWithAuthMethod,
      total,
      skip,
      take,
    };
  }

  async getPendingUsers() {
    const users = await this.prisma.user.findMany({
      where: { status: UserStatus.pending },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        name: true,
        isAdmin: true,
        status: true,
        oidcSubject: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    const usersWithAuthMethod = users.map(({ oidcSubject, ...rest }) => ({
      ...rest,
      authMethod: oidcSubject ? ('oidc' as const) : ('local' as const),
    }));

    return usersWithAuthMethod;
  }

  async createUser(createUserDto: CreateUserDto) {
    const existingUser = await this.prisma.user.findUnique({
      where: { email: createUserDto.email },
    });

    if (existingUser) {
      throw new ConflictException('User already exists');
    }

    const hashedPassword = await bcrypt.hash(createUserDto.password, 10);

    const user = await this.prisma.user.create({
      data: {
        email: createUserDto.email,
        password: hashedPassword,
        name: createUserDto.name,
        isAdmin: false,
      },
      select: {
        id: true,
        email: true,
        name: true,
        isAdmin: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return user;
  }

  async updateUser(id: string, updateUserDto: UpdateUserDto) {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check if email is being changed and if it's already taken
    if (updateUserDto.email && updateUserDto.email !== user.email) {
      const existingUser = await this.prisma.user.findUnique({
        where: { email: updateUserDto.email },
      });

      if (existingUser) {
        throw new ConflictException('Email already in use');
      }
    }

    const updatedUser = await this.prisma.user.update({
      where: { id },
      data: updateUserDto,
      select: {
        id: true,
        email: true,
        name: true,
        isAdmin: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return updatedUser;
  }

  async deleteUser(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.isAdmin) {
      // Check if this is the last admin
      const adminCount = await this.prisma.user.count({
        where: { isAdmin: true },
      });

      if (adminCount === 1) {
        throw new BadRequestException('Cannot delete the last admin user');
      }
    }

    // Delete user - notes and tags will be cascade deleted by database constraint
    await this.prisma.user.delete({
      where: { id },
    });

    return { message: 'User deleted successfully' };
  }

  async resetPassword(id: string, newPassword?: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Generate secure random password if not provided
    const password =
      newPassword ||
      crypto
        .randomBytes(12)
        .toString('base64')
        .replace(/[+/=]/g, '')
        .slice(0, 16);

    const hashedPassword = await bcrypt.hash(password, 10);

    await this.prisma.user.update({
      where: { id },
      data: { password: hashedPassword },
    });

    // Return the new password (only if it was auto-generated)
    return {
      newPassword: newPassword ? undefined : password,
      message: newPassword
        ? 'Password reset successfully'
        : 'Password reset successfully. New password generated.',
    };
  }

  async approveUser(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.status !== UserStatus.pending) {
      throw new BadRequestException('User is not pending approval');
    }

    const updatedUser = await this.prisma.user.update({
      where: { id },
      data: { status: UserStatus.active },
      select: {
        id: true,
        email: true,
        name: true,
        isAdmin: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return updatedUser;
  }

  async rejectUser(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.status !== UserStatus.pending) {
      throw new BadRequestException('User is not pending approval');
    }

    // Delete the user
    await this.prisma.user.delete({
      where: { id },
    });

    return { message: 'User rejected and deleted successfully' };
  }

  async getOidcSettings() {
    return this.oidcConfigService.getOidcSettings();
  }

  async updateOidcSettings(settings: {
    enabled?: boolean;
    providerName?: string;
    issuerUrl?: string;
    clientId?: string;
    clientSecret?: string;
    clearClientSecret?: boolean;
    disableInternalAuth?: boolean;
  }) {
    const { clearClientSecret, ...rest } = settings;
    const toSet = { ...rest };
    if (clearClientSecret) {
      toSet.clientSecret = '';
    }
    await this.oidcConfigService.setOidcSettings(toSet);
    return this.oidcConfigService.getOidcSettings();
  }
}

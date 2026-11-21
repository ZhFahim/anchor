import { Inject, Injectable, Logger, ConflictException } from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import * as fs from 'fs/promises';
import * as path from 'path';
import { deleteFileIfExists } from '../../common/utils/file-system.util';
import { Prisma } from '../../generated/prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { UserStatus } from '../../generated/prisma/enums';
import type { OidcUserClaims } from './oidc.types';
import { OIDC_USER_SELECT, CONTENT_TYPE_EXT_MAP } from './oidc.constants';
import { StorageConfig } from '../../config/configuration';
import { PUBLIC_PROFILES_PREFIX } from '../../config/storage.constants';
import { coded } from '../../common/errors/coded';
import { ErrorCode } from '../../common/errors/error-code';

@Injectable()
export class OidcUserService {
  private readonly logger = new Logger(OidcUserService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(StorageConfig.KEY)
    private readonly storageConfig: ConfigType<typeof StorageConfig>,
  ) {}

  /**
   * Find or create user based on OIDC claims.
   * Automatically links accounts when email matches (no existing OIDC link).
   */
  async findOrCreateUser(claims: OidcUserClaims) {
    try {
      return await this.prisma.$transaction(
        async (tx) => {
          const existingBySubject = await tx.user.findUnique({
            where: { oidcSubject: claims.subject },
            select: OIDC_USER_SELECT,
          });
          if (existingBySubject) {
            const updateData: { name?: string; profileImage?: string | null } =
              {
                name: claims.name,
              };
            const profileImage = await this.resolveProfileImage(
              claims.picture,
              existingBySubject.id,
              existingBySubject.profileImage,
            );
            if (profileImage !== undefined) {
              updateData.profileImage = profileImage;
            }
            await tx.user.update({
              where: { id: existingBySubject.id },
              data: updateData,
            });
            return tx.user.findUniqueOrThrow({
              where: { id: existingBySubject.id },
              select: OIDC_USER_SELECT,
            });
          }

          const existingByEmail = await tx.user.findUnique({
            where: { email: claims.email },
          });
          if (existingByEmail) {
            if (
              existingByEmail.oidcSubject != null &&
              existingByEmail.oidcSubject !== claims.subject
            ) {
              throw coded(
                new ConflictException(
                  'This email is already linked to a different sign-in account.',
                ),
                ErrorCode.EMAIL_LINKED_ELSEWHERE,
              );
            }
            const updateData: {
              oidcSubject?: string;
              name?: string;
              profileImage?: string | null;
            } = {
              name: claims.name,
            };
            if (!existingByEmail.oidcSubject) {
              updateData.oidcSubject = claims.subject;
              this.logger.log(
                `Linked OIDC subject to existing user: ${claims.email}`,
              );
            }
            const profileImage = await this.resolveProfileImage(
              claims.picture,
              existingByEmail.id,
              existingByEmail.profileImage,
            );
            if (profileImage !== undefined) {
              updateData.profileImage = profileImage;
            }
            await tx.user.update({
              where: { id: existingByEmail.id },
              data: updateData,
            });
            return tx.user.findUniqueOrThrow({
              where: { id: existingByEmail.id },
              select: OIDC_USER_SELECT,
            });
          }

          return this.createUserInTx(tx, claims, UserStatus.active);
        },
        { timeout: 10000 },
      );
    } catch (error) {
      if (error instanceof ConflictException) {
        throw error;
      }
      // P2002 = unique constraint violation; concurrent create, re-fetch by subject
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const user = await this.prisma.user.findUnique({
          where: { oidcSubject: claims.subject },
          select: OIDC_USER_SELECT,
        });
        if (user) {
          return user;
        }
      }
      throw error;
    }
  }

  /**
   * Create a new user from OIDC claims (within a transaction).
   */
  private async createUserInTx(
    tx: Prisma.TransactionClient,
    claims: OidcUserClaims,
    status: UserStatus = UserStatus.active,
  ) {
    const adminCount = await tx.user.count({
      where: { isAdmin: true },
    });

    const newUser = await tx.user.create({
      data: {
        email: claims.email,
        name: claims.name,
        password: null,
        oidcSubject: claims.subject,
        isAdmin: adminCount === 0,
        status,
      },
      select: OIDC_USER_SELECT,
    });

    const profileImage = await this.resolveProfileImage(
      claims.picture,
      newUser.id,
      null,
    );
    if (profileImage) {
      await tx.user.update({
        where: { id: newUser.id },
        data: { profileImage },
      });
    }

    this.logger.log(`Created new OIDC user: ${claims.email}`);
    return tx.user.findUniqueOrThrow({
      where: { id: newUser.id },
      select: OIDC_USER_SELECT,
    });
  }

  /**
   * Resolve profile image from OIDC picture claim.
   * Tries to download and store; falls back to URL if download fails.
   */
  private async resolveProfileImage(
    pictureUrl: string | undefined,
    userId: string,
    oldProfileImage: string | null,
  ): Promise<string | null | undefined> {
    if (!pictureUrl) return undefined;
    const downloaded = await this.downloadPicture(
      pictureUrl,
      userId,
      oldProfileImage,
    );
    if (downloaded) return downloaded;
    try {
      const url = new URL(pictureUrl);
      return url.protocol === 'https:' ? pictureUrl : undefined;
    } catch {
      return undefined;
    }
  }

  private async downloadPicture(
    pictureUrl: string,
    userId: string,
    oldProfileImagePath: string | null,
  ): Promise<string | null> {
    try {
      const response = await fetch(pictureUrl);
      if (!response.ok) return null;

      const contentType = response.headers
        .get('content-type')
        ?.split(';')[0]
        ?.trim();
      const ext = contentType
        ? (CONTENT_TYPE_EXT_MAP[contentType] ?? '.jpg')
        : '.jpg';
      const filename = `${userId}-oidc-${Date.now()}${ext}`;
      const profilesDir = this.storageConfig.profilesDir;
      const filePath = path.join(profilesDir, filename);
      const imagePath = `${PUBLIC_PROFILES_PREFIX}/${filename}`;

      await fs.mkdir(profilesDir, { recursive: true });
      await fs.writeFile(filePath, Buffer.from(await response.arrayBuffer()));

      if (
        oldProfileImagePath?.startsWith(PUBLIC_PROFILES_PREFIX) &&
        oldProfileImagePath.includes('-oidc-')
      ) {
        const oldFullPath = path.join(
          profilesDir,
          path.basename(oldProfileImagePath),
        );
        await deleteFileIfExists(oldFullPath, this.logger);
      }

      this.logger.log(`Downloaded OIDC avatar for user ${userId}`);
      return imagePath;
    } catch (error) {
      this.logger.warn(
        `Failed to download OIDC picture: ${error instanceof Error ? error.message : String(error)}`,
      );
      return null;
    }
  }
}

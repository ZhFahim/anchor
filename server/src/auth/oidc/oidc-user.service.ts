import {
  Injectable,
  Logger,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import type { Prisma } from '../../generated/prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { SettingsService } from '../../settings/settings.service';
import { UserStatus } from '../../generated/prisma/enums';
import type { OidcUserClaims } from './oidc.types';
import {
  UPLOADS_DIR,
  UPLOADS_PROFILES_PATH,
  OIDC_USER_SELECT,
  CONTENT_TYPE_EXT_MAP,
} from './oidc.constants';

@Injectable()
export class OidcUserService {
  private readonly logger = new Logger(OidcUserService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly settingsService: SettingsService,
  ) {}

  /**
   * Find or create user based on OIDC claims.
   * Automatically links accounts when email matches (no existing OIDC link).
   */
  async findOrCreateUser(claims: OidcUserClaims) {
    const registrationMode = await this.settingsService.getRegistrationMode();
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
              throw new ConflictException(
                'This email is already linked to a different sign-in account.',
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

          if (registrationMode === 'disabled') {
            throw new ForbiddenException('Registration is disabled');
          }
          const status =
            registrationMode === 'review'
              ? UserStatus.pending
              : UserStatus.active;
          return this.createUserInTx(tx, claims, status);
        },
        { timeout: 10000 },
      );
    } catch (error) {
      if (error instanceof ConflictException) {
        throw error;
      }
      // P2002 = unique constraint violation; concurrent create, re-fetch by subject
      if (error?.code === 'P2002') {
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
      const filePath = path.join(UPLOADS_DIR, filename);
      const imagePath = `/uploads/profiles/${filename}`;

      if (!fs.existsSync(UPLOADS_DIR)) {
        fs.mkdirSync(UPLOADS_DIR, { recursive: true });
      }
      fs.writeFileSync(filePath, Buffer.from(await response.arrayBuffer()));

      if (
        oldProfileImagePath?.startsWith(UPLOADS_PROFILES_PATH) &&
        oldProfileImagePath.includes('-oidc-')
      ) {
        const oldFullPath = path.join(
          UPLOADS_DIR,
          path.basename(oldProfileImagePath),
        );
        if (fs.existsSync(oldFullPath)) {
          try {
            fs.unlinkSync(oldFullPath);
          } catch {
            this.logger.warn(
              `Failed to delete old profile image: ${oldFullPath}`,
            );
          }
        }
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

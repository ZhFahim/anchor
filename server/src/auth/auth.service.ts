import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { SettingsService } from '../settings/settings.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UserStatus } from '../generated/prisma/enums';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';
import { generateApiToken } from './utils/generate-api-token';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private settingsService: SettingsService,
  ) { }

  async getRegistrationMode() {
    return {
      mode: await this.settingsService.getRegistrationMode(),
    };
  }

  async register(registerDto: RegisterDto) {
    const registrationMode = await this.settingsService.getRegistrationMode();

    if (registrationMode === 'disabled') {
      throw new ForbiddenException('Registration is disabled');
    }

    const existingUser = await this.prisma.user.findUnique({
      where: { email: registerDto.email },
    });

    if (existingUser) {
      throw new ConflictException('User already exists');
    }

    const hashedPassword = await bcrypt.hash(registerDto.password, 10);

    // Check if this is the first user (no admins exist)
    const adminCount = await this.prisma.user.count({
      where: { isAdmin: true },
    });

    // Determine user status based on registration mode
    const userStatus =
      registrationMode === 'review' ? UserStatus.pending : UserStatus.active;

    const user = await this.prisma.user.create({
      data: {
        email: registerDto.email,
        password: hashedPassword,
        name: registerDto.name,
        isAdmin: adminCount === 0, // First user becomes admin
        status: userStatus,
      },
      select: {
        id: true,
        email: true,
        name: true,
        profileImage: true,
        isAdmin: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    // Only return token if user is active (not pending)
    if (user.status === UserStatus.active) {
      const tokens = await this.createTokenPair(user.id, user.email);
      return {
        ...tokens,
        user,
      };
    }

    // Return without token for pending users
    return {
      user,
      message: 'Registration successful. Your account is pending approval.',
    };
  }

  async login(loginDto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: loginDto.email },
      select: {
        id: true,
        email: true,
        password: true,
        name: true,
        profileImage: true,
        isAdmin: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // OIDC users don't have passwords - they must use OIDC login
    if (!user.password) {
      throw new UnauthorizedException(
        'This account uses OIDC authentication. Please use the OIDC login option.',
      );
    }

    const isPasswordValid = await bcrypt.compare(
      loginDto.password,
      user.password,
    );

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check if user is pending approval
    if (user.status === UserStatus.pending) {
      throw new ForbiddenException(
        'Account pending approval. Please wait for an administrator to approve your account.',
      );
    }

    // Remove password from user object
    const { password: _, ...userWithoutPassword } = user;

    const tokens = await this.createTokenPair(user.id, user.email);
    return {
      ...tokens,
      user: userWithoutPassword,
    };
  }

  async refreshTokens(refreshToken: string) {
    // Find the refresh token in database
    const storedToken = await this.prisma.refreshToken.findUnique({
      where: { token: refreshToken },
      include: { user: true },
    });

    if (!storedToken) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    // Check if token has expired
    if (storedToken.expiresAt < new Date()) {
      // Delete expired token
      await this.prisma.refreshToken.delete({
        where: { id: storedToken.id },
      });
      throw new UnauthorizedException('Refresh token has expired');
    }

    // Check if user is still active
    if (storedToken.user.status === UserStatus.pending) {
      throw new UnauthorizedException('Account pending approval');
    }

    // Revoke the old refresh token (token rotation)
    await this.prisma.refreshToken.delete({
      where: { id: storedToken.id },
    });

    // Generate new token pair
    const tokens = await this.createTokenPair(
      storedToken.user.id,
      storedToken.user.email,
    );

    return tokens;
  }

  async getApiToken(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, status: true, apiToken: true },
    });

    if (!user) {
      throw new ForbiddenException('User not found');
    }

    if (user.status !== UserStatus.active) {
      throw new ForbiddenException('Account pending approval');
    }

    return { apiToken: user.apiToken };
  }

  async revokeApiToken(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, status: true },
    });

    if (!user) {
      throw new ForbiddenException('User not found');
    }

    if (user.status !== UserStatus.active) {
      throw new ForbiddenException('Account pending approval');
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: { apiToken: null },
    });

    return { apiToken: null };
  }

  async regenerateApiToken(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, status: true },
    });

    if (!user) {
      throw new ForbiddenException('User not found');
    }

    if (user.status !== UserStatus.active) {
      throw new ForbiddenException('Account pending approval');
    }

    const apiToken = await this.generateUniqueApiToken();
    await this.prisma.user.update({
      where: { id: userId },
      data: { apiToken },
    });

    return { apiToken };
  }

  async changePassword(userId: string, changePasswordDto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, password: true },
    });

    if (!user) {
      throw new ForbiddenException('User not found');
    }

    // OIDC users don't have passwords
    if (!user.password) {
      throw new BadRequestException(
        'Password change is not available for OIDC-authenticated users. Please change your password through your identity provider.',
      );
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(
      changePasswordDto.currentPassword,
      user.password,
    );

    if (!isCurrentPasswordValid) {
      throw new ForbiddenException('Current password is incorrect');
    }

    // Check if new password is different from current password
    const isSamePassword = await bcrypt.compare(
      changePasswordDto.newPassword,
      user.password,
    );

    if (isSamePassword) {
      throw new BadRequestException(
        'New password must be different from current password',
      );
    }

    // Hash and update password
    const hashedPassword = await bcrypt.hash(changePasswordDto.newPassword, 10);

    await this.prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword },
    });

    return { message: 'Password changed successfully' };
  }

  async updateProfile(userId: string, updateProfileDto: UpdateProfileDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!user) {
      throw new ForbiddenException('User not found');
    }

    try {
      const updatedUser = await this.prisma.user.update({
        where: { id: userId },
        data: { name: updateProfileDto.name },
        select: {
          id: true,
          email: true,
          name: true,
          profileImage: true,
          isAdmin: true,
          status: true,
          createdAt: true,
          updatedAt: true,
        },
      });

      return updatedUser;
    } catch (error) {
      throw new BadRequestException(
        'Failed to update profile. Please try again.',
      );
    }
  }

  async uploadProfileImage(userId: string, file: Express.Multer.File) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, profileImage: true },
    });

    if (!user) {
      throw new ForbiddenException('User not found');
    }

    // Ensure uploads directory exists
    const uploadsDir = '/data/uploads/profiles';
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    // File validation is handled at controller level with ParseFilePipe
    // Generate unique filename
    const timestamp = Date.now();
    const ext = path.extname(file.originalname);
    const filename = `${userId}-${timestamp}${ext}`;
    const filePath = path.join(uploadsDir, filename);
    const imagePath = `/uploads/profiles/${filename}`;

    const oldImagePath: string | null = user.profileImage || null;
    let fileSaved = false;

    try {
      // Save new file first
      fs.writeFileSync(filePath, file.buffer);
      fileSaved = true;

      // Update database with new image path
      const updatedUser = await this.prisma.user.update({
        where: { id: userId },
        data: { profileImage: imagePath },
        select: {
          id: true,
          email: true,
          name: true,
          profileImage: true,
          isAdmin: true,
          status: true,
          createdAt: true,
          updatedAt: true,
        },
      });

      // Delete old image only after successful database update
      if (oldImagePath && oldImagePath !== imagePath) {
        await this.deleteProfileImage(oldImagePath);
      }

      return updatedUser;
    } catch (error) {
      // If database update fails, delete the newly uploaded file
      if (fileSaved && fs.existsSync(filePath)) {
        try {
          fs.unlinkSync(filePath);
        } catch (deleteError) {
          this.logger.error(`Failed to delete newly uploaded file after DB error: ${filePath}`);
        }
      }
      throw new BadRequestException(
        'Failed to upload profile image. Please try again.',
      );
    }
  }

  async removeProfileImage(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, profileImage: true },
    });

    if (!user) {
      throw new ForbiddenException('User not found');
    }

    const oldImagePath: string | null = user.profileImage || null;

    try {
      const updatedUser = await this.prisma.user.update({
        where: { id: userId },
        data: { profileImage: null },
        select: {
          id: true,
          email: true,
          name: true,
          profileImage: true,
          isAdmin: true,
          status: true,
          createdAt: true,
          updatedAt: true,
        },
      });

      // Delete old image only after successful database update
      if (oldImagePath) {
        await this.deleteProfileImage(oldImagePath);
      }

      return updatedUser;
    } catch (error) {
      throw new BadRequestException(
        'Failed to remove profile image. Please try again.',
      );
    }
  }

  private async deleteProfileImage(profileImagePath: string): Promise<void> {
    if (!profileImagePath) return;

    try {
      // Remove /uploads prefix to get actual file path
      const relativePath = profileImagePath.startsWith('/uploads/')
        ? profileImagePath.substring('/uploads/'.length)
        : profileImagePath;

      const fullPath = path.join('/data', relativePath);
      if (fs.existsSync(fullPath)) {
        fs.unlinkSync(fullPath);
      }
    } catch (error) {
      this.logger.error(`Failed to delete old profile image at ${profileImagePath}`);
    }
  }

  // Generate a secure random refresh token
  private generateRefreshTokenString(): string {
    return crypto.randomBytes(64).toString('hex');
  }

  private async generateUniqueApiToken(): Promise<string> {
    // Retry a few times to avoid edge-case collisions on the unique column.
    for (let i = 0; i < 5; i++) {
      const candidate = generateApiToken();
      const existingUser = await this.prisma.user.findUnique({
        where: { apiToken: candidate },
        select: { id: true },
      });

      if (!existingUser) {
        return candidate;
      }
    }

    throw new BadRequestException(
      'Failed to generate API token. Please try again.',
    );
  }

  /**
   * Create access and refresh token pair for a user.
   * Used by login, register, and OIDC flows.
   */
  async createTokenPair(userId: string, email: string) {
    const payload = { email, sub: userId };

    // Generate access token (short-lived)
    const accessToken = this.jwtService.sign(payload);

    // Generate refresh token (long-lived)
    const refreshTokenString = this.generateRefreshTokenString();
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30); // 30 days

    // Store refresh token in database
    await this.prisma.refreshToken.create({
      data: {
        token: refreshTokenString,
        userId,
        expiresAt,
      },
    });

    return {
      access_token: accessToken,
      refresh_token: refreshTokenString,
    };
  }
}

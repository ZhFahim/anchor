import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
  ForbiddenException,
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
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class AuthService {
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
      const payload = { email: user.email, sub: user.id };
      return {
        access_token: this.jwtService.sign(payload),
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
        isAdmin: true,
        status: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
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

    // Fetch full user with profile fields
    const fullUser = await this.prisma.user.findUnique({
      where: { id: userWithoutPassword.id },
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

    const payload = { email: fullUser!.email, sub: fullUser!.id };
    return {
      access_token: this.jwtService.sign(payload),
      user: fullUser,
    };
  }

  async changePassword(userId: string, changePasswordDto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, password: true },
    });

    if (!user) {
      throw new ForbiddenException('User not found');
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
      throw new BadRequestException('New password must be different from current password');
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

    let oldImagePath: string | null = user.profileImage || null;
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
          console.error(
            `Failed to delete newly uploaded file after DB error: ${filePath}`,
            deleteError,
          );
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
      console.error(
        `Failed to delete old profile image at ${profileImagePath}:`,
        error,
      );
    }
  }
}

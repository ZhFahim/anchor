import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  HttpCode,
  HttpStatus,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthService } from './auth.service';
import { MagicLoginService } from './magic-login.service';
import { MagicLoginDto } from './dto/magic-login.dto';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { LogoutDto } from './dto/logout.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { CurrentUser } from './decorators/current-user.decorator';
import { PROFILE_IMAGE_MAX_BYTES } from './constants/auth.constants';
import type { User } from 'src/generated/prisma/client';

@Controller('api/auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly magicLoginService: MagicLoginService,
  ) {}

  @Get('registration-mode')
  getRegistrationMode() {
    return this.authService.getRegistrationMode();
  }

  @Post('register')
  register(@Body() registerDto: RegisterDto) {
    return this.authService.register(registerDto);
  }

  @HttpCode(HttpStatus.OK)
  @Post('login')
  login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }

  @HttpCode(HttpStatus.OK)
  @Post('refresh')
  refresh(@Body() refreshTokenDto: RefreshTokenDto) {
    return this.authService.refreshTokens(refreshTokenDto.refresh_token);
  }

  @HttpCode(HttpStatus.OK)
  @Post('logout')
  async logout(@Body() logoutDto: LogoutDto): Promise<void> {
    return this.authService.revokeRefreshToken(logoutDto.refreshToken);
  }

  /** A one-time code that signs another device in as this person. */
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post('magic-login')
  createMagicLogin(@CurrentUser() user: User) {
    return this.magicLoginService.create(user.id);
  }

  @HttpCode(HttpStatus.OK)
  @Post('magic-login/redeem')
  redeemMagicLogin(@Body() magicLoginDto: MagicLoginDto) {
    return this.magicLoginService.redeem(magicLoginDto.code);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  getMe(@CurrentUser() user: User) {
    return this.authService.getMe(user);
  }

  @UseGuards(JwtAuthGuard)
  @Get('api-token')
  getApiToken(@CurrentUser() user: User) {
    return this.authService.getApiToken(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('api-token')
  revokeApiToken(@CurrentUser() user: User) {
    return this.authService.revokeApiToken(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post('api-token/regenerate')
  regenerateApiToken(@CurrentUser() user: User) {
    return this.authService.regenerateApiToken(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  @Post('change-password')
  changePassword(
    @CurrentUser() user: User,
    @Body() changePasswordDto: ChangePasswordDto,
  ) {
    return this.authService.changePassword(user.id, changePasswordDto);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('profile')
  async updateProfile(
    @CurrentUser() user: User,
    @Body() updateProfileDto: UpdateProfileDto,
  ) {
    return this.authService.updateProfile(user.id, updateProfileDto);
  }

  @UseGuards(JwtAuthGuard)
  @Post('profile/image')
  @UseInterceptors(
    FileInterceptor('image', {
      limits: { fileSize: PROFILE_IMAGE_MAX_BYTES, files: 1 },
    }),
  )
  async uploadProfileImage(
    @CurrentUser() user: User,
    @UploadedFile(
      new ParseFilePipe({
        fileIsRequired: true,
        validators: [
          new MaxFileSizeValidator({ maxSize: PROFILE_IMAGE_MAX_BYTES }),
          // Checks the file's content; the detected type replaces the one
          // the client declared, and decides the stored extension.
          new FileTypeValidator({
            fileType: /^image\/(jpeg|png|webp)$/,
            overrideMimeType: true,
          }),
        ],
      }),
    )
    file: Express.Multer.File,
  ) {
    return this.authService.uploadProfileImage(user.id, file);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('profile/image')
  async removeProfileImage(@CurrentUser() user: User) {
    return this.authService.removeProfileImage(user.id);
  }
}

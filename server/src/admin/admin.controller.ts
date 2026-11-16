import {
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AdminService } from './admin.service';
import { AdminGuard } from './admin.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UserStatus } from 'src/generated/prisma/enums';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { UpdateRegistrationModeDto } from './dto/update-registration-mode.dto';
import { UpdateOidcSettingsDto } from './dto/update-oidc-settings.dto';
import { UpdateTwoFactorPolicyDto } from '../auth/two-factor/dto/two-factor.dto';

@Controller('api/admin')
@UseGuards(AdminGuard)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('stats')
  getStats() {
    return this.adminService.getStats();
  }

  @Get('settings/registration')
  getRegistrationSettings() {
    return this.adminService.getRegistrationSettings();
  }

  @Patch('settings/registration')
  updateRegistrationMode(@Body() dto: UpdateRegistrationModeDto) {
    return this.adminService.updateRegistrationMode(dto.mode);
  }

  @Get('settings/two-factor')
  getTwoFactorSettings() {
    return this.adminService.getTwoFactorSettings();
  }

  @Patch('settings/two-factor')
  updateTwoFactorPolicy(
    @Body() dto: UpdateTwoFactorPolicyDto,
    @CurrentUser('id') currentUserId: string,
  ) {
    return this.adminService.updateTwoFactorPolicy(dto.policy, currentUserId);
  }

  @Get('users')
  findUsers(
    @Query('skip') skip?: string,
    @Query('take') take?: string,
    @Query('q') q?: string,
    @Query('status') status?: string,
  ) {
    return this.adminService.findUsers(
      skip ? parseInt(skip, 10) : 0,
      take ? parseInt(take, 10) : 50,
      {
        q: q?.trim() || undefined,
        status:
          status === UserStatus.active || status === UserStatus.pending
            ? status
            : undefined,
      },
    );
  }

  @Get('users/pending')
  getPendingUsers() {
    return this.adminService.getPendingUsers();
  }

  @Post('users')
  createUser(@Body() createUserDto: CreateUserDto) {
    return this.adminService.createUser(createUserDto);
  }

  @Patch('users/:id')
  updateUser(
    @Param('id') id: string,
    @Body() updateUserDto: UpdateUserDto,
    @CurrentUser('id') currentUserId: string,
  ) {
    return this.adminService.updateUser(id, updateUserDto, currentUserId);
  }

  @Delete('users/:id')
  deleteUser(@Param('id') id: string) {
    return this.adminService.deleteUser(id);
  }

  @Post('users/:id/reset-password')
  resetPassword(
    @Param('id') id: string,
    @Body() resetPasswordDto: ResetPasswordDto,
  ) {
    return this.adminService.resetPassword(id, resetPasswordDto.newPassword);
  }

  @HttpCode(HttpStatus.OK)
  @Post('users/:id/reset-2fa')
  resetTwoFactor(@Param('id') id: string) {
    return this.adminService.resetTwoFactor(id);
  }

  @Post('users/:id/approve')
  approveUser(@Param('id') id: string) {
    return this.adminService.approveUser(id);
  }

  @Post('users/:id/reject')
  rejectUser(@Param('id') id: string) {
    return this.adminService.rejectUser(id);
  }

  @Get('settings/oidc')
  getOidcSettings() {
    return this.adminService.getOidcSettings();
  }

  @Patch('settings/oidc')
  updateOidcSettings(@Body() dto: UpdateOidcSettingsDto) {
    return this.adminService.updateOidcSettings(dto);
  }
}

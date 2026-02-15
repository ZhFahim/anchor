import {
  Controller,
  Get,
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
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { UpdateRegistrationModeDto } from './dto/update-registration-mode.dto';
import { UpdateOidcSettingsDto } from './dto/update-oidc-settings.dto';

@Controller('api/admin')
@UseGuards(AdminGuard)
export class AdminController {
  constructor(private readonly adminService: AdminService) { }

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

  @Get('users')
  findAllUsers(@Query('skip') skip?: string, @Query('take') take?: string) {
    return this.adminService.findAllUsers(
      skip ? parseInt(skip, 10) : 0,
      take ? parseInt(take, 10) : 50,
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
  updateUser(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    return this.adminService.updateUser(id, updateUserDto);
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

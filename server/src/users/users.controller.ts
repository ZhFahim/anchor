import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UsersService } from './users.service';

@Controller('api/users')
@UseGuards(AuthGuard)
export class UsersController {
  constructor(private usersService: UsersService) { }

  @Get('search')
  searchUsers(
    @CurrentUser('id') userId: string,
    @Query('q') searchQuery?: string,
  ) {
    return this.usersService.searchUsers(searchQuery || '', userId);
  }
}

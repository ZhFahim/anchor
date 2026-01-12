import { IsIn } from 'class-validator';

export class UpdateRegistrationModeDto {
  @IsIn(['disabled', 'enabled', 'review'])
  mode: 'disabled' | 'enabled' | 'review';
}

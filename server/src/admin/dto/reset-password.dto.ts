import { IsOptional, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @IsOptional()
  @MinLength(8)
  newPassword?: string;
}


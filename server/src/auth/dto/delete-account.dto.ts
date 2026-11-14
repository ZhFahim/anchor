import { IsOptional, IsString } from 'class-validator';

export class DeleteAccountDto {
  @IsOptional()
  @IsString()
  password?: string;
}

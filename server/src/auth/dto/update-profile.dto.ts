import { IsOptional, IsString, MaxLength } from 'class-validator';
import { Transform } from 'class-transformer';

export class UpdateProfileDto {
  @IsOptional()
  @Transform(({ value }) => value ? value.trim() : undefined)
  @IsString()
  @MaxLength(100)
  name?: string;
}

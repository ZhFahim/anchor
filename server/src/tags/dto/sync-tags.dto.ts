import { IsArray, IsOptional, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class TagChangeDto {
  @IsString()
  id: string;

  @IsString()
  name: string;

  @IsString()
  @IsOptional()
  color?: string;

  @IsString()
  @IsOptional()
  updatedAt?: string;

  @IsOptional()
  isDeleted?: boolean;
}

export class SyncTagsDto {
  @IsString()
  @IsOptional()
  lastSyncedAt?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TagChangeDto)
  @IsOptional()
  changes?: TagChangeDto[];
}

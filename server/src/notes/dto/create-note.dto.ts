import { IsBoolean, IsOptional, IsString, IsArray } from 'class-validator';

export class CreateNoteDto {
  // Blank is allowed and canonical for "no title"; clients render an "Untitled" placeholder.
  @IsString()
  title: string;

  @IsString()
  @IsOptional()
  content?: string;

  @IsBoolean()
  @IsOptional()
  isPinned?: boolean;

  @IsBoolean()
  @IsOptional()
  isArchived?: boolean;

  @IsString()
  @IsOptional()
  background?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  tagIds?: string[];
}

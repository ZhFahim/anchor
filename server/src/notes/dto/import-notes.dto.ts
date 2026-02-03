import { IsArray, IsNotEmpty, IsOptional, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateNoteDto } from './create-note.dto';

export class ImportNoteItemDto extends CreateNoteDto {
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  labels?: string[];
}

export class ImportNotesDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ImportNoteItemDto)
  @IsNotEmpty()
  notes: ImportNoteItemDto[];
}

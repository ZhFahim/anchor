import { IsArray, ValidateNested, IsString, IsInt } from 'class-validator';
import { Type } from 'class-transformer';

class NotePositionDto {
  @IsString()
  id: string;

  @IsInt()
  position: number;
}

export class ReorderNotesDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => NotePositionDto)
  positions: NotePositionDto[];
}

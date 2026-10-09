import { OmitType, PartialType } from '@nestjs/mapped-types';
import { IsBoolean, IsInt, IsOptional, Min } from 'class-validator';
import { CreateNoteDto } from './create-note.dto';

export class UpdateNoteDto extends PartialType(
  OmitType(CreateNoteDto, ['id'] as const),
) {
  // Version the client based its edit on. Stale → 409 with the full
  // serverNote; absent → unconditional write.
  @IsInt()
  @Min(1)
  @IsOptional()
  baseVersion?: number;

  // History keeps the text this save replaces, even if the same person wrote it.
  @IsBoolean()
  @IsOptional()
  replacesOtherEdit?: boolean;
}

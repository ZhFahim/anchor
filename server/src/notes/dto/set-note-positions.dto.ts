import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsNotEmpty,
  IsString,
  Matches,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import {
  MAX_POSITIONS_PER_REQUEST,
  ORDER_KEY_PATTERN,
} from '../../common/ordering/order-key';

export class NotePositionDto {
  @IsString()
  @IsNotEmpty()
  noteId: string;

  // null takes the note out of the order (it goes back to the top).
  @ValidateIf((_, value) => value !== null)
  @IsString()
  @Matches(ORDER_KEY_PATTERN)
  position: string | null;
}

export class SetNotePositionsDto {
  @IsArray()
  @ArrayMaxSize(MAX_POSITIONS_PER_REQUEST)
  @ValidateNested({ each: true })
  @Type(() => NotePositionDto)
  positions: NotePositionDto[];
}

import { PartialType, PickType } from '@nestjs/mapped-types';
import { CreateNoteDto } from 'src/notes/dto/create-note.dto';

export class UpdateHomarrNoteDto extends PartialType(
  PickType(CreateNoteDto, ['title', 'content'] as const),
) {}

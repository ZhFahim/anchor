import { IsString, IsNotEmpty, IsEnum } from 'class-validator';
import { NoteSharePermission } from 'src/generated/prisma/enums';

export class ShareNoteDto {
  @IsString()
  @IsNotEmpty()
  sharedWithUserId: string;

  @IsEnum(NoteSharePermission)
  permission: NoteSharePermission;
}

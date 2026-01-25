import { IsEnum } from 'class-validator';
import { NoteSharePermission } from 'src/generated/prisma/enums';

export class UpdateNoteSharePermissionDto {
  @IsEnum(NoteSharePermission)
  permission: NoteSharePermission;
}

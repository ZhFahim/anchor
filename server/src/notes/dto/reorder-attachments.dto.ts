import { IsArray, ArrayNotEmpty, IsUUID } from 'class-validator';

export class ReorderAttachmentsDto {
  @IsArray()
  @ArrayNotEmpty()
  @IsUUID('4', { each: true })
  orderedIds: string[];
}

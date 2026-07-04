import { IsInt, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class ImportAttachmentDto {
  // Multipart form field, transformed from string
  @Type(() => Number)
  @IsInt()
  @Min(0)
  position: number;
}

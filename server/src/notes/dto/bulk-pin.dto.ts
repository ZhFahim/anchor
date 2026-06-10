import { IsArray, IsBoolean, IsNotEmpty, IsString } from 'class-validator';

export class BulkPinDto {
  @IsArray()
  @IsString({ each: true })
  @IsNotEmpty({ each: true })
  noteIds: string[];

  @IsBoolean()
  isPinned: boolean;
}

import { IsArray, IsString, IsNotEmpty } from 'class-validator';

export class BulkActionDto {
  @IsArray()
  @IsString({ each: true })
  @IsNotEmpty({ each: true })
  noteIds: string[];
}

import { IsArray, IsNotEmpty, IsString } from 'class-validator';

export class BulkTagsDto {
  @IsArray()
  @IsString({ each: true })
  @IsNotEmpty({ each: true })
  noteIds: string[];

  @IsArray()
  @IsString({ each: true })
  @IsNotEmpty({ each: true })
  tagIds: string[];
}

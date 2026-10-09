import { IsIn, IsOptional } from 'class-validator';

const EXPORT_FORMATS = ['anchor', 'markdown'] as const;

export type ExportFormat = (typeof EXPORT_FORMATS)[number];

export class ExportQueryDto {
  @IsIn(EXPORT_FORMATS)
  @IsOptional()
  format?: ExportFormat;
}

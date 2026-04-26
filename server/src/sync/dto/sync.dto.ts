import {
  IsString,
  IsOptional,
  IsArray,
  IsObject,
  ValidateNested,
  IsIn,
} from 'class-validator';
import { Type } from 'class-transformer';

export type SyncEntityType = 'note' | 'tag' | 'note_attachment';
export type SyncOpKind = 'upsert' | 'delete';

export class SyncOpDto {
  @IsString()
  clientOpId: string;

  @IsString()
  @IsIn(['note', 'tag', 'note_attachment'])
  entityType: SyncEntityType;

  @IsString()
  entityId: string;

  @IsString()
  @IsIn(['upsert', 'delete'])
  op: SyncOpKind;

  @IsString()
  @IsOptional()
  baseSyncVersion?: string;

  @IsObject()
  @IsOptional()
  payload?: Record<string, unknown>;
}

export class SyncRequestDto {
  @IsString()
  @IsOptional()
  cursor?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncOpDto)
  @IsOptional()
  ops?: SyncOpDto[];
}

export interface SyncOpResult {
  clientOpId: string;
  status: 'applied' | 'noop' | 'rejected';
  entityId: string;
  syncVersion?: string;
  serverRow?: unknown;
  serverWon?: boolean;
  reason?: string;
}

export interface SyncServerChange {
  entityType: SyncEntityType;
  syncVersion: string;
  data: unknown;
  isDeleted?: boolean;
}

export interface SyncResponse {
  results: SyncOpResult[];
  serverChanges: SyncServerChange[];
  revokedSharedNoteIds: string[];
  newCursor: string;
  hasMore: boolean;
}

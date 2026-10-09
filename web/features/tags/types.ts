export interface Tag {
  id: string;
  name: string;
  color?: string;
  version: number;
  updatedAt?: string;
  _count?: {
    notes: number;
  };
}

export type TagLabel = Pick<Tag, "id" | "name" | "color">;

export interface CreateTagDto {
  name: string;
  color?: string;
}

export interface UpdateTagDto {
  name?: string;
  color?: string;
  baseVersion?: number;
}

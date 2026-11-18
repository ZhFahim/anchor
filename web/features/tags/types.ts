export interface Tag {
  id: string;
  name: string;
  color?: string;
  /** The tag's place in Custom order (a fractional key). */
  position?: string | null;
  version: number;
  updatedAt?: string;
  _count?: {
    notes: number;
  };
}

export type TagLabel = Pick<Tag, "id" | "name" | "color" | "position">;

export interface CreateTagDto {
  name: string;
  color?: string;
}

export interface UpdateTagDto {
  name?: string;
  color?: string;
  baseVersion?: number;
}

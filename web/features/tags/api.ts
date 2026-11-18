import { api } from "@/lib/api/client";
import type { CreateTagDto, Tag, UpdateTagDto } from "./types";

export async function getTags(): Promise<Tag[]> {
  return api.get("api/tags").json<Tag[]>();
}

export async function createTag(data: CreateTagDto): Promise<Tag> {
  return api.post("api/tags", { json: data }).json<Tag>();
}

export async function updateTag(id: string, data: UpdateTagDto): Promise<Tag> {
  return api.patch(`api/tags/${id}`, { json: data }).json<Tag>();
}

const POSITIONS_PER_REQUEST = 500;

/** Places tags in the person's own order. */
export async function setTagPositions(
  positions: { id: string; position: string | null }[],
): Promise<void> {
  for (let i = 0; i < positions.length; i += POSITIONS_PER_REQUEST)
    await api.put("api/tags/positions", {
      json: { positions: positions.slice(i, i + POSITIONS_PER_REQUEST) },
    });
}

export async function deleteTag(id: string): Promise<void> {
  await api.delete(`api/tags/${id}`);
}

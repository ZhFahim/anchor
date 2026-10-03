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

export async function deleteTag(id: string): Promise<void> {
  await api.delete(`api/tags/${id}`);
}

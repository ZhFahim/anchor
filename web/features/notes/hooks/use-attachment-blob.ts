"use client";

import { useQuery } from "@tanstack/react-query";
import { useEffect } from "react";
import { fetchAttachmentBlob } from "../api";

const CACHE_MS = 10 * 60 * 1000;

const urls = new Map<Blob, { url: string; users: number; timer?: number }>();

function revokeLater(blob: Blob) {
  const entry = urls.get(blob);
  if (!entry) return;
  entry.timer = window.setTimeout(() => {
    URL.revokeObjectURL(entry.url);
    urls.delete(blob);
  }, CACHE_MS);
}

export function blobUrlFor(blob: Blob) {
  let entry = urls.get(blob);
  if (!entry) {
    entry = { url: URL.createObjectURL(blob), users: 0 };
    urls.set(blob, entry);
    revokeLater(blob);
  }
  return entry.url;
}

export function releaseBlobUrl(blob: Blob) {
  const entry = urls.get(blob);
  if (!entry || entry.users > 0) return;
  window.clearTimeout(entry.timer);
  URL.revokeObjectURL(entry.url);
  urls.delete(blob);
}

function takeUrl(blob: Blob) {
  const entry = urls.get(blob);
  if (!entry) return;
  window.clearTimeout(entry.timer);
  entry.users++;
}

function dropUrl(blob: Blob) {
  const entry = urls.get(blob);
  if (!entry || --entry.users > 0) return;
  revokeLater(blob);
}

interface UseAttachmentBlobResult {
  blobUrl: string | null;
  isLoading: boolean;
  error: string | null;
  retry: () => void;
}

export function useAttachmentBlob(
  noteId: string,
  attachmentId: string,
  isWanted = true,
): UseAttachmentBlobResult {
  const query = useQuery({
    queryKey: ["attachment-file", noteId, attachmentId],
    queryFn: () => fetchAttachmentBlob(noteId, attachmentId),
    enabled: isWanted && !!noteId && !!attachmentId,
    staleTime: Number.POSITIVE_INFINITY,
    gcTime: CACHE_MS,
    retry: 1,
  });
  const blob = query.data;
  const blobUrl = blob ? blobUrlFor(blob) : null;

  useEffect(() => {
    if (!blob) return;
    takeUrl(blob);
    return () => dropUrl(blob);
  }, [blob]);

  return {
    blobUrl,
    isLoading: !blobUrl && query.isFetching,
    error: query.error
      ? query.error instanceof Error
        ? query.error.message
        : "Failed to load"
      : null,
    retry: () => void query.refetch(),
  };
}

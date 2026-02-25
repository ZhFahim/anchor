"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { fetchAttachmentBlob } from "../api";

interface UseAttachmentBlobResult {
  blobUrl: string | null;
  isLoading: boolean;
  error: string | null;
  retry: () => void;
}

export function useAttachmentBlob(
  noteId: string,
  attachmentId: string
): UseAttachmentBlobResult {
  const [blobUrl, setBlobUrl] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [retryCount, setRetryCount] = useState(0);
  const urlRef = useRef<string | null>(null);

  const loadBlob = useCallback(async () => {
    if (urlRef.current) {
      URL.revokeObjectURL(urlRef.current);
      urlRef.current = null;
    }
    setBlobUrl(null);
    setIsLoading(true);
    setError(null);

    try {
      const blob = await fetchAttachmentBlob(noteId, attachmentId);
      const url = URL.createObjectURL(blob);
      urlRef.current = url;
      setBlobUrl(url);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load");
    } finally {
      setIsLoading(false);
    }
  }, [noteId, attachmentId]);

  useEffect(() => {
    loadBlob();
  }, [loadBlob, retryCount]);

  useEffect(() => {
    return () => {
      if (urlRef.current) {
        URL.revokeObjectURL(urlRef.current);
        urlRef.current = null;
      }
    };
  }, []);

  const retry = useCallback(() => {
    setRetryCount((c) => c + 1);
  }, []);

  return { blobUrl, isLoading, error, retry };
}

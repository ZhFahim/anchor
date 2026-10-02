import { getAccessToken } from "@/features/auth/store";
import { refreshAccessToken } from "./client";

interface UploadOptions {
  /** 0 to 1 as the file goes up. */
  onProgress?: (done: number) => void;
  signal?: AbortSignal;
}

function send(path: string, body: FormData, options: UploadOptions) {
  return new Promise<{ status: number; text: string }>((resolve, reject) => {
    if (options.signal?.aborted) {
      reject(new DOMException("Upload canceled", "AbortError"));
      return;
    }
    const xhr = new XMLHttpRequest();
    xhr.open("POST", `/${path}`);
    const token = getAccessToken();
    if (token) xhr.setRequestHeader("Authorization", `Bearer ${token}`);
    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable) options.onProgress?.(e.loaded / e.total);
    };
    xhr.onload = () => resolve({ status: xhr.status, text: xhr.responseText });
    xhr.onerror = () => reject(new Error("Couldn’t reach the server"));
    xhr.onabort = () =>
      reject(new DOMException("Upload canceled", "AbortError"));
    options.signal?.addEventListener("abort", () => xhr.abort(), {
      once: true,
    });
    xhr.send(body);
  });
}

/** XMLHttpRequest: fetch has no upload progress. */
export async function uploadWithProgress<T>(
  path: string,
  body: FormData,
  options: UploadOptions = {},
): Promise<T> {
  let response = await send(path, body, options);
  if (response.status === 401 && (await refreshAccessToken()))
    response = await send(path, body, options);
  let data: unknown = null;
  try {
    data = JSON.parse(response.text);
  } catch {}
  if (response.status < 200 || response.status >= 300) {
    const message = (data as { message?: string | string[] } | null)?.message;
    throw new Error(
      Array.isArray(message)
        ? message.join(", ")
        : (message ?? `Upload failed (${response.status})`),
    );
  }
  return data as T;
}

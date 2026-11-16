"use client";

import { useSearchParams } from "next/navigation";
import type { ReactNode } from "react";
import { useColumns } from "@/features/notes/hooks/use-columns";
import { NotesView } from "./notes-view";

/** In columns, the list stays on screen while notes open beside it. */
export default function NotesLayout({ children }: { children: ReactNode }) {
  const tagId = useSearchParams().get("tagId");
  const isColumns = useColumns();
  if (!isColumns) return children;
  return <NotesView key={tagId ?? ""} tagId={tagId} openNote={children} />;
}

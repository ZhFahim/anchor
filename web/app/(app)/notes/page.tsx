"use client";

import { useSearchParams } from "next/navigation";
import { EmptyState } from "@/components/ui/empty-state";
import { useColumns } from "@/features/notes/hooks/use-columns";
import { NotesView } from "./notes-view";

export default function NotesPage() {
  const tagId = useSearchParams().get("tagId");
  const isColumns = useColumns();
  // In columns the layout shows the list; this page is the empty side.
  if (isColumns)
    return (
      <EmptyState illustration="notes" title="No note open" className="m-auto">
        Pick a note from the list, or press N to start a new one.
      </EmptyState>
    );
  // Next keeps the page mounted when only the tag changes.
  return <NotesView key={tagId ?? ""} tagId={tagId} />;
}

import type { Metadata } from "next";
import type { ReactNode } from "react";

// A shared note is for whoever holds the link, not for search engines.
export const metadata: Metadata = {
  title: "Shared note · Anchor",
  robots: { index: false, follow: false },
  referrer: "no-referrer",
};

export default function PublicNoteLayout({
  children,
}: {
  children: ReactNode;
}) {
  return children;
}

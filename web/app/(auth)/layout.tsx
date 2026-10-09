"use client";

import type { ReactNode } from "react";
import { AuthShell, GuestGuard } from "@/features/auth";

export default function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <GuestGuard>
      <AuthShell>{children}</AuthShell>
    </GuestGuard>
  );
}

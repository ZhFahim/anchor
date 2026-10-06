"use client";

import { useRouter } from "next/navigation";
import { type ReactNode, useEffect } from "react";
import { useAuthStore } from "@/features/auth/store";

interface AdminGuardProps {
  children: ReactNode;
}

export function AdminGuard({ children }: AdminGuardProps) {
  const router = useRouter();
  const isAdmin = useAuthStore((state) => !!state.user?.isAdmin);

  useEffect(() => {
    if (!isAdmin) router.replace("/notes");
  }, [isAdmin, router]);

  return isAdmin ? children : null;
}

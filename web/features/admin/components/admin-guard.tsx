"use client";

import { useRouter } from "next/navigation";
import { type ReactNode, useEffect } from "react";
import { useAuth } from "@/features/auth";

interface AdminGuardProps {
  children: ReactNode;
}

export function AdminGuard({ children }: AdminGuardProps) {
  const router = useRouter();
  const { user, isAuthenticated, isInitialized, initialize } = useAuth();

  useEffect(() => {
    initialize();
  }, [initialize]);

  useEffect(() => {
    if (isInitialized) {
      if (!isAuthenticated) {
        router.push("/login");
      } else if (!user?.isAdmin) {
        router.push("/");
      }
    }
  }, [isInitialized, isAuthenticated, user, router]);

  // Show loading state while initializing
  if (!isInitialized) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="w-8 h-8 border-2 border-accent border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  // Don't render children if not authenticated or not admin
  if (!isAuthenticated || !user?.isAdmin) {
    return null;
  }

  return <>{children}</>;
}

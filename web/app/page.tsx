"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { SplashScreen } from "@/components/layout/splash-screen";
import { SessionCheck } from "@/features/auth/components/session-check";
import { useAuthStore } from "@/features/auth/store";

export default function Home() {
  const router = useRouter();
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const isInitialized = useAuthStore((state) => state.isInitialized);

  useEffect(() => {
    if (!isInitialized) return;

    if (isAuthenticated) {
      router.replace("/notes");
    } else {
      router.replace("/login");
    }
  }, [isInitialized, isAuthenticated, router]);

  return (
    <SessionCheck>
      <SplashScreen checking={false} />
    </SessionCheck>
  );
}

"use client";

import { Lock } from "lucide-react";

interface ReadOnlyBannerProps {
  message: string;
}

export function ReadOnlyBanner({ message }: ReadOnlyBannerProps) {
  return (
    <div className="sticky top-16 z-30 border-b border-border/30 bg-muted/50 backdrop-blur-sm">
      <div className="max-w-3xl mx-auto px-4 lg:px-6 py-3">
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <Lock className="h-4 w-4" />
          <span>{message}</span>
        </div>
      </div>
    </div>
  );
}

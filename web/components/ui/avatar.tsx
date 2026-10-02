"use client";

import * as AvatarPrimitive from "@radix-ui/react-avatar";
import { cva, type VariantProps } from "class-variance-authority";
import type * as React from "react";
import { avatarColor, initials } from "@/lib/avatar";
import { cn } from "@/lib/utils";

const avatarVariants = cva(
  "inline-grid flex-none select-none place-items-center overflow-hidden rounded-full font-bold text-avatar-text tracking-[.01em]",
  {
    variants: {
      size: {
        xs: "size-5 text-[10px]",
        sm: "size-6 text-[10.5px]",
        md: "size-7.5 text-small",
        lg: "size-16 text-[24px]",
        xl: "size-19 text-display",
      },
    },
    defaultVariants: { size: "md" },
  },
);

const shownPhotos = new Set<string>();

type AvatarProps = VariantProps<typeof avatarVariants> & {
  id?: string;
  children?: React.ReactNode;
  name?: string | null;
  src?: string | null;
  ring?: boolean;
  className?: string;
  title?: string;
};

function Avatar({
  id = "",
  name,
  src,
  size,
  ring,
  className,
  title,
  children,
}: AvatarProps) {
  return (
    <AvatarPrimitive.Root
      data-slot="avatar"
      title={title}
      aria-hidden
      className={cn(
        avatarVariants({ size }),
        ring && "shadow-[0_0_0_2px_var(--note)]",
        className,
      )}
      style={{
        backgroundColor: `var(--color-avatar-${avatarColor(id || name || "")})`,
      }}
    >
      {children ??
        (src && shownPhotos.has(src) ? (
          <img src={src} alt="" className="size-full object-cover" />
        ) : (
          <>
            {src && (
              <AvatarPrimitive.Image
                src={src}
                alt=""
                className="size-full object-cover"
                onLoadingStatusChange={(status) => {
                  if (status === "loaded") shownPhotos.add(src);
                }}
              />
            )}
            <AvatarPrimitive.Fallback delayMs={src ? 400 : undefined}>
              {initials(name)}
            </AvatarPrimitive.Fallback>
          </>
        ))}
    </AvatarPrimitive.Root>
  );
}

async function preloadPhoto(src: string) {
  const image = new Image();
  image.src = src;
  try {
    await image.decode();
    shownPhotos.add(src);
  } catch {}
}

export { Avatar, preloadPhoto };

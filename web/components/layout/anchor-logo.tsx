"use client";

import { useId } from "react";
import { cn } from "@/lib/utils";

/** The app icon, in its 1024 by 1024 units. */
export function AnchorLogo({ className }: { className?: string }) {
  const id = useId();
  const paper = `${id}paper`;
  const top = `${id}top`;
  const page = `${id}page`;
  return (
    <svg
      viewBox="0 0 1024 1024"
      aria-hidden
      className={cn("flex-none rounded-sm shadow-edge", className)}
    >
      <defs>
        <linearGradient
          id={paper}
          gradientUnits="userSpaceOnUse"
          x1="0"
          y1="0"
          x2="0"
          y2="1024"
        >
          <stop className="[stop-color:#ffffff] dark:[stop-color:#30343f]" />
          <stop
            offset="1"
            className="[stop-color:#e9eef4] dark:[stop-color:#1b1d23]"
          />
        </linearGradient>
        <linearGradient
          id={top}
          gradientUnits="userSpaceOnUse"
          x1="0"
          y1="0"
          x2="0"
          y2="276"
        >
          <stop className="[stop-color:#f59a6c] dark:[stop-color:#ea8558]" />
          <stop
            offset="1"
            className="[stop-color:#ec7743] dark:[stop-color:#d66a3a]"
          />
        </linearGradient>
        <clipPath id={page}>
          <rect width="1024" height="1024" rx="256" />
        </clipPath>
      </defs>
      <g clipPath={`url(#${page})`}>
        <rect width="1024" height="1024" fill={`url(#${paper})`} />
        <rect width="1024" height="276" fill={`url(#${top})`} />
        <g className="fill-[#d5dbe4] dark:fill-[#4a5164]">
          <rect x="168" y="392" width="688" height="64" rx="32" />
          <rect x="168" y="540" width="300" height="64" rx="32" />
          <rect x="168" y="688" width="230" height="64" rx="32" />
        </g>
        <g
          transform="translate(494 516) scale(3.8)"
          fill="none"
          strokeWidth="13"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="stroke-[#2d3142] dark:stroke-[#f1f4f8]"
        >
          <circle cx="50" cy="18" r="9" />
          <path d="M50 27V94M10 54A40 40 0 0 0 90 54M10 54H22M90 54H78" />
        </g>
      </g>
    </svg>
  );
}

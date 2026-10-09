import Link from "next/link";
import { cn } from "@/lib/utils";

export function AnchorLogo({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 32 32"
      aria-hidden
      className={cn("flex-none rounded-sm shadow-edge", className)}
    >
      <rect width="32" height="32" rx="8" fill="#eef1f6" />
      <path
        d="M2.6 9V7.9A6.6 6.6 0 0 1 9.2 1.3h13.6a6.6 6.6 0 0 1 6.6 6.6V9Z"
        fill="#ef8354"
      />
      <g fill="#dcdfe4">
        <rect x="5.1" y="12.6" width="21.8" height="1.3" rx=".65" />
        <rect x="5.1" y="17" width="12.2" height="1.3" rx=".65" />
        <rect x="5.1" y="21.4" width="9.4" height="1.3" rx=".65" />
      </g>
      <g fill="none" stroke="#b9bec6" strokeWidth=".9" strokeLinecap="round">
        <circle cx="22.9" cy="19.2" r="1.1" />
        <path d="M22.9 20.3v6.2M19.3 23.4h1.1M25.4 23.4h1.2M19.3 23.4a3.6 3.6 0 0 0 7.3 0" />
      </g>
    </svg>
  );
}

const wordmarkClass =
  "whitespace-nowrap font-bold font-serif text-[19px] tracking-[-.005em]";

export function Brand({
  href,
  className,
  nameClassName,
  onNavigate,
}: {
  href?: string;
  className?: string;
  nameClassName?: string;
  onNavigate?: () => void;
}) {
  const content = (
    <>
      <AnchorLogo className="size-7" />
      <span data-slot="brand-name" className={cn(wordmarkClass, nameClassName)}>
        Anchor
      </span>
    </>
  );
  const classes = cn(
    "flex min-w-0 flex-1 items-center gap-2 rounded-sm text-inherit no-underline",
    className,
  );
  return href ? (
    <Link href={href} className={classes} onClick={onNavigate}>
      {content}
    </Link>
  ) : (
    <span className={classes}>{content}</span>
  );
}

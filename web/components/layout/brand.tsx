import Link from "next/link";
import { cn } from "@/lib/utils";
import { AnchorLogo } from "./anchor-logo";

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

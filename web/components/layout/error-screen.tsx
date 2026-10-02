"use client";

import * as React from "react";
import {
  StateIllustration,
  type StateIllustrationKind,
} from "@/components/ui/state-illustration";

interface ErrorScreenProps {
  illustration: StateIllustrationKind;
  code?: string;
  title: string;
  text: React.ReactNode;
  actions: React.ReactNode;
  children?: React.ReactNode;
}

export function ErrorScreen({
  illustration,
  code,
  title,
  text,
  actions,
  children,
}: ErrorScreenProps) {
  const heading = React.useRef<HTMLHeadingElement>(null);
  React.useEffect(() => heading.current?.focus({ preventScroll: true }), []);
  return (
    <div className="mx-auto grid max-w-115 justify-items-center gap-3 px-2 pt-8 pb-12 text-center max-md:pt-4">
      <StateIllustration
        kind={illustration}
        className="mb-1 w-55 max-w-full max-md:w-45"
      />
      {code && (
        <span className="rounded-pill bg-muted px-2.5 py-0.5 font-medium font-mono text-muted-foreground text-small">
          {code}
        </span>
      )}
      <h1
        ref={heading}
        tabIndex={-1}
        className="m-0 text-balance text-page outline-none"
      >
        {title}
      </h1>
      <p className="m-0 max-w-[40ch] text-pretty text-lead text-muted-foreground">
        {text}
      </p>
      <div className="mt-2 flex flex-wrap justify-center gap-2">{actions}</div>
      {children}
    </div>
  );
}

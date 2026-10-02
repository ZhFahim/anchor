import type * as React from "react";
import { cn } from "@/lib/utils";

function Table({ className, ...props }: React.ComponentProps<"table">) {
  return (
    <div data-slot="table-scroll" className="overflow-x-auto">
      <table
        className={cn(
          "w-full min-w-180 border-collapse text-control",
          className,
        )}
        {...props}
      />
    </div>
  );
}

function TableHeader(props: React.ComponentProps<"thead">) {
  return <thead {...props} />;
}

function TableBody(props: React.ComponentProps<"tbody">) {
  return <tbody {...props} />;
}

function TableHead({ className, ...props }: React.ComponentProps<"th">) {
  return (
    <th
      className={cn(
        "whitespace-nowrap border-border/55 border-b px-3.5 py-2 text-left font-semibold text-label text-muted-foreground uppercase tracking-[.04em]",
        className,
      )}
      {...props}
    />
  );
}

function TableRow({ className, ...props }: React.ComponentProps<"tr">) {
  return (
    <tr
      className={cn(
        "hover:[&>td]:bg-foreground/2.5 [&:first-child>td]:border-t-0",
        className,
      )}
      {...props}
    />
  );
}

function TableCell({
  className,
  numeric,
  dim,
  ...props
}: React.ComponentProps<"td"> & { numeric?: boolean; dim?: boolean }) {
  return (
    <td
      className={cn(
        "whitespace-nowrap border-border/45 border-t px-3.5 py-2.5 align-middle",
        numeric && "text-right text-muted-foreground tabular-nums",
        dim && "text-muted-foreground",
        className,
      )}
      {...props}
    />
  );
}

export { Table, TableBody, TableCell, TableHead, TableHeader, TableRow };

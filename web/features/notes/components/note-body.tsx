import { CircleCheck } from "lucide-react";
import * as React from "react";
import { cn } from "@/lib/utils";
import {
  type DoneRow,
  foldTickedItems,
  type InlineRun,
  type NoteBlock,
} from "../note-blocks";

type ListKind = "check" | "bullet" | "ordered";
type Row = NoteBlock | DoneRow;
type Segment =
  | { key: number; list: ListKind; items: { key: number; block: NoteBlock }[] }
  | { key: number; row: Row };

interface NoteBodyProps {
  blocks: NoteBlock[];
  variant?: "card" | "full";
  maxRows?: number;
  className?: string;
  ref?: React.Ref<HTMLDivElement>;
}

const isList = (t: Row["type"]): t is ListKind =>
  t === "check" || t === "bullet" || t === "ordered";

function toSegments(rows: Row[]): Segment[] {
  const segments: Segment[] = [];
  rows.forEach((row, key) => {
    const last = segments[segments.length - 1];
    if (isList(row.type) && "level" in row) {
      if (last && "list" in last && last.list === row.type)
        last.items.push({ key, block: row });
      else segments.push({ key, list: row.type, items: [{ key, block: row }] });
    } else segments.push({ key, row });
  });
  return segments;
}

export function NoteBody({
  blocks,
  variant = "full",
  maxRows = Number.POSITIVE_INFINITY,
  className,
  ref,
}: NoteBodyProps) {
  const card = variant === "card";
  const shown = blocks.filter(
    (b) => b.type === "code" || b.runs.some((r) => r.text.trim()),
  );
  let rows: Row[] = card ? foldTickedItems(shown) : shown;
  const truncated = rows.length > maxRows;
  rows = rows.slice(0, maxRows);

  return (
    <div
      ref={ref}
      className={cn(
        "doc",
        card && "is-card",
        card && truncated && "cut",
        className,
      )}
    >
      {toSegments(rows).map((segment) => {
        if ("list" in segment) {
          const Tag = segment.list === "ordered" ? "ol" : "ul";
          return (
            <Tag
              key={segment.key}
              className={
                { check: "lst ck", bullet: "lst bul", ordered: "lst num" }[
                  segment.list
                ]
              }
            >
              {segment.items.map(({ key, block }) => (
                <li
                  key={key}
                  data-lvl={block.level}
                  style={{ "--lvl": block.level } as React.CSSProperties}
                  className={block.done ? "done" : undefined}
                >
                  {block.type === "check" ? (
                    <span className="box" aria-hidden />
                  ) : (
                    <span className="mk" aria-hidden>
                      {block.type === "ordered" ? block.marker : ""}
                    </span>
                  )}
                  <span className="tx">
                    {block.type === "check" && (
                      <span className="sr-only">
                        {block.done ? "Checked: " : "Not checked: "}
                      </span>
                    )}
                    <TextRuns runs={block.runs} card={card} />
                  </span>
                </li>
              ))}
            </Tag>
          );
        }
        return <Block key={segment.key} row={segment.row} card={card} />;
      })}
    </div>
  );
}

function Block({ row, card }: { row: Row; card: boolean }) {
  if (row.type === "done")
    return (
      <div className="sum">
        <CircleCheck aria-hidden />
        {row.isAll && row.count > 1
          ? `All ${row.count} done`
          : `${row.count} done`}
      </div>
    );
  const block = row as NoteBlock;
  const text = <TextRuns runs={block.runs} card={card} />;
  if (block.type === "h1" || block.type === "h2" || block.type === "h3") {
    const headingClass = `x-${block.type}`;
    if (card) return <p className={headingClass}>{text}</p>;
    const Tag = ({ h1: "h2", h2: "h3", h3: "h4" } as const)[block.type];
    return <Tag className={headingClass}>{text}</Tag>;
  }
  if (block.type === "quote") return <blockquote>{text}</blockquote>;
  if (block.type === "code")
    return (
      <div className="code-wrap">
        <pre className="code">{block.runs.map((r) => r.text).join("")}</pre>
      </div>
    );
  return <p>{text}</p>;
}

export function TextRuns({ runs, card }: { runs: InlineRun[]; card: boolean }) {
  return runs.map((run, i) => {
    let node: React.ReactNode = run.text;
    if (run.code) node = <code>{node}</code>;
    if (run.strike) node = <s>{node}</s>;
    if (run.underline) node = <u>{node}</u>;
    if (run.italic) node = <em>{node}</em>;
    if (run.bold) node = <strong>{node}</strong>;
    if (run.highlight)
      node = (
        <mark className="hl" data-hl={run.highlight}>
          {node}
        </mark>
      );
    if (run.link)
      node = card ? (
        <span className="lnk">{node}</span>
      ) : (
        <a
          className="lnk"
          href={run.link}
          target="_blank"
          rel="noopener noreferrer"
        >
          {node}
        </a>
      );
    return <React.Fragment key={i}>{node}</React.Fragment>;
  });
}

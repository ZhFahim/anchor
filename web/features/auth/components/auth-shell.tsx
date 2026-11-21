"use client";

import { Paperclip, Users } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import * as React from "react";
import { Brand } from "@/components/layout/brand";
import { Toaster } from "@/components/ui/toast";
import { NoteBody } from "@/features/notes/components/note-body";
import { ReminderChip } from "@/features/notes/components/reminder-chip";
import type { NoteBlock } from "@/features/notes/note-blocks";
import { toWallClock } from "@/features/notes/reminder";
import { TagChip } from "@/features/tags/components/tag-chip";
import { LanguageMenu } from "@/i18n/language-menu";
import type { Translate } from "@/i18n/translate";
import { onHighlightRepaint, paintHighlights } from "@/lib/highlight-paint";

const PHOTOS = [
  {
    sky: ["#f4bf98", "#f5dcc3", "#d3e3ea"],
    sun: "#fbe7cb",
    hill: "#b8c7cd",
    river: ["#a7c8d6", "#6d9db3"],
  },
  {
    sky: ["#8fc2e8", "#c6e0f2", "#e9f2f6"],
    sun: "#fff4d2",
    hill: "#9fb8a6",
    river: ["#7db2cb", "#4d88a4"],
  },
  {
    sky: ["#383c68", "#86699b", "#e0a68c"],
    sun: "#f5d0a4",
    hill: "#5a5775",
    river: ["#686e96", "#3e4370"],
  },
];

function SamplePhoto({ index }: { index: number }) {
  const photo = PHOTOS[index];
  const id = React.useId().replace(/:/g, "");
  return (
    <svg
      viewBox="0 0 600 400"
      preserveAspectRatio="xMidYMid slice"
      aria-hidden
      className="block size-full"
    >
      <defs>
        <linearGradient id={`${id}s`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={photo.sky[0]} />
          <stop offset=".6" stopColor={photo.sky[1]} />
          <stop offset="1" stopColor={photo.sky[2]} />
        </linearGradient>
        <linearGradient id={`${id}r`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={photo.river[0]} />
          <stop offset="1" stopColor={photo.river[1]} />
        </linearGradient>
      </defs>
      <rect width="600" height="400" fill={`url(#${id}s)`} />
      <circle cx="440" cy="150" r="44" fill={photo.sun} />
      <path d="M0 246 Q140 212 270 236 T600 224 V400 H0Z" fill={photo.hill} />
      <rect y="258" width="600" height="142" fill={`url(#${id}r)`} />
      <path d="M300 300 H600" stroke="#e9f2f5" strokeWidth="2" opacity=".5" />
      <path d="M340 330 H560" stroke="#e9f2f5" strokeWidth="2" opacity=".4" />
      <rect x="0" y="262" width="78" height="138" fill="#f1e2c6" />
      <path d="M-6 266 L39 232 L84 266Z" fill="#c4633a" />
      <rect x="72" y="292" width="64" height="108" fill="#e9b8a8" />
      <path d="M66 296 L104 266 L142 296Z" fill="#b8552f" />
      <rect x="130" y="276" width="74" height="124" fill="#f3d58e" />
      <path d="M124 280 L167 246 L210 280Z" fill="#c4633a" />
      <rect x="198" y="312" width="60" height="88" fill="#dfe6e8" />
      <path d="M192 316 L228 290 L264 316Z" fill="#b8552f" />
      <g fill="#7b5a48" opacity=".55">
        <rect x="16" y="290" width="12" height="16" />
        <rect x="46" y="290" width="12" height="16" />
        <rect x="16" y="324" width="12" height="16" />
        <rect x="46" y="324" width="12" height="16" />
        <rect x="88" y="316" width="11" height="15" />
        <rect x="112" y="316" width="11" height="15" />
        <rect x="146" y="302" width="12" height="16" />
        <rect x="176" y="302" width="12" height="16" />
        <rect x="146" y="338" width="12" height="16" />
        <rect x="176" y="338" width="12" height="16" />
        <rect x="212" y="334" width="11" height="14" />
        <rect x="234" y="334" width="11" height="14" />
      </g>
    </svg>
  );
}

type Run = NoteBlock["runs"][number];

const run = (text: string, extra: Partial<Run> = {}) => ({
  text,
  ...extra,
});

const MARKS: Record<string, Partial<Run>> = {
  b: { bold: true },
  yellow: { highlight: "yellow" },
  green: { highlight: "green" },
  blue: { highlight: "blue" },
};

const markTags = Object.fromEntries(
  Object.keys(MARKS).map((tag) => [
    tag,
    (chunks: string) => `<${tag}>${chunks}</${tag}>`,
  ]),
);

const runsOf = (markup: string): Run[] =>
  markup
    .split(/(<\w+>.*?<\/\w+>)/)
    .filter(Boolean)
    .map((part) => {
      const marked = /^<(\w+)>(.*)<\/\1>$/.exec(part);
      return marked ? run(marked[2], MARKS[marked[1]]) : run(part);
    });

const paragraph = (...runs: NoteBlock["runs"]): NoteBlock => ({
  type: "p",
  level: 0,
  runs,
});
const check = (text: string, done = false): NoteBlock => ({
  type: "check",
  level: 0,
  runs: [run(text)],
  done,
});
const numbered = (
  level: number,
  marker: string,
  ...runs: NoteBlock["runs"]
): NoteBlock => ({ type: "ordered", level, runs, marker });
const bullet = (level: number, ...runs: NoteBlock["runs"]): NoteBlock => ({
  type: "bullet",
  level,
  runs,
});

const inDays = (days: number, hour: number) => {
  const at = new Date();
  at.setDate(at.getDate() + days);
  at.setHours(hour, 0, 0, 0);
  return toWallClock(at);
};

interface Sample {
  key: string;
  bg: string;
  title: string;
  blocks: NoteBlock[];
  tags: [string, string][];
  date: string;
  pics?: number[];
  files?: number;
  shares?: number;
  reminder?: string;
  placement: [string, string, string, string];
}

function samplesFor(t: Translate, locale: string): Sample[] {
  const marked = (
    key:
      | "authSampleTripText"
      | "authSampleGoalsReleaseNotes"
      | "authSampleBreadRest",
  ) => runsOf(t.markup(key, markTags));
  const shortDate = new Intl.DateTimeFormat(locale, {
    month: "short",
    day: "numeric",
  });
  const september = (day: number) => shortDate.format(new Date(2025, 8, day));
  return [
    {
      key: "lisbon",
      bg: "pattern_travel",
      title: t("authSampleTripTitle"),
      pics: [0, 1, 2],
      files: 4,
      shares: 1,
      reminder: inDays(3, 9),
      blocks: [
        paragraph(...marked("authSampleTripText")),
        { type: "h1", level: 0, runs: [run(t("authSampleTripHeading"))] },
        check(t("authSampleTripPassport")),
        check(t("authSampleTripChargers")),
      ],
      tags: [
        ["#64B5F6", t("authSampleTagTravel")],
        ["#FF8A65", t("authSampleTagFamily")],
      ],
      date: t("authSampleToday"),
      placement: ["8%", "6%", "-6deg", "0s"],
    },
    {
      key: "goals",
      bg: "color_yellow",
      title: t("authSampleGoalsTitle"),
      reminder: inDays(-2, 17),
      blocks: [
        numbered(0, "1.", run(t("authSampleGoalsSync"))),
        numbered(1, "a.", run(t("authSampleGoalsRetry"))),
        numbered(1, "b.", run(t("authSampleGoalsSlowNetwork"))),
        numbered(0, "2.", run(t("authSampleGoalsEditor"))),
        numbered(0, "3.", ...marked("authSampleGoalsReleaseNotes")),
      ],
      tags: [
        ["#7986CB", t("authSampleTagWork")],
        ["#E57373", t("authSampleTagBugs")],
      ],
      date: september(22),
      placement: ["52%", "3%", "5deg", "-2s"],
    },
    {
      key: "groc",
      bg: "pattern_groceries",
      title: t("authSampleGroceriesTitle"),
      blocks: [
        check(t("authSampleGroceriesOatMilk")),
        check(t("authSampleGroceriesBread")),
        check(t("authSampleGroceriesTomatoes")),
        check(t("authSampleGroceriesCoffee")),
      ],
      tags: [["#FFB74D", t("authSampleTagShopping")]],
      date: t("authSampleToday"),
      placement: ["30%", "33%", "2deg", "-4s"],
    },
    {
      key: "reading",
      bg: "color_purple",
      title: t("authSampleReadingTitle"),
      shares: 2,
      reminder: inDays(1, 8),
      blocks: [
        bullet(0, run(t("authSampleReadingFirstBook"), { italic: true })),
        bullet(1, run(t("authSampleReadingChapter"))),
        bullet(0, run(t("authSampleReadingSecondBook"))),
        {
          type: "quote",
          level: 0,
          runs: [run(t("authSampleReadingQuote"))],
        },
      ],
      tags: [["#9575CD", t("authSampleTagReading")]],
      date: september(20),
      placement: ["62%", "40%", "-4deg", "-6s"],
    },
    {
      key: "bread",
      bg: "pattern_dots",
      title: t("authSampleBreadTitle"),
      files: 1,
      blocks: [
        numbered(0, "1.", run(t("authSampleBreadStarter"))),
        numbered(0, "2.", run(t("authSampleBreadMix"))),
        numbered(0, "3.", ...marked("authSampleBreadRest")),
        numbered(0, "4.", run(t("authSampleBreadFold"))),
        numbered(0, "5.", run(t("authSampleBreadShape"))),
        numbered(0, "6.", run(t("authSampleBreadBake"))),
      ],
      tags: [["#FFD54F", t("authSampleTagRecipes")]],
      date: september(18),
      placement: ["4%", "52%", "7deg", "-3s"],
    },
  ];
}

function SampleCard({ sample }: { sample: Sample }) {
  const [left, top, rotation, delay] = sample.placement;
  const pics = sample.pics ?? [];
  return (
    <article
      data-note={sample.bg}
      className="nc"
      style={
        { left, top, "--r": rotation, "--d": delay } as React.CSSProperties
      }
    >
      {pics.length > 0 && (
        <div className={`nc-pics n${pics.length}`}>
          {pics.map((photo, i) => (
            <div key={photo} className="ph">
              <SamplePhoto index={photo} />
              {i === pics.length - 1 && (sample.files ?? 0) > pics.length && (
                <span className="more">
                  +{(sample.files ?? 0) - pics.length}
                </span>
              )}
            </div>
          ))}
        </div>
      )}
      <div className="nc-in">
        <div className="nc-title">{sample.title}</div>
        <NoteBody blocks={sample.blocks} variant="card" maxRows={6} />
        <div className="nc-tags">
          {sample.tags.map(([color, name]) => (
            <TagChip key={name} name={name} color={color} size="sm" />
          ))}
        </div>
        <div className="nc-foot">
          {sample.reminder && (
            <ReminderChip
              noteId={`sample-${sample.key}`}
              reminder={{
                remindAt: sample.reminder,
                recurrence: "none",
                version: 0,
              }}
              size="sm"
            />
          )}
          {sample.shares ? (
            <span className="nc-count">
              <Users aria-hidden />
              {sample.shares}
            </span>
          ) : null}
          {sample.files && !pics.length ? (
            <span className="nc-count">
              <Paperclip aria-hidden />
              {sample.files}
            </span>
          ) : null}
          <span className="nc-date">{sample.date}</span>
        </div>
      </div>
    </article>
  );
}

function useCollageHighlights(
  collage: React.RefObject<HTMLDivElement | null>,
  samples: Sample[],
) {
  // biome-ignore lint/correctness/useExhaustiveDependencies: repaint when the sample text changes language
  React.useLayoutEffect(() => {
    const el = collage.current;
    if (!el) return;
    const paint = () => {
      // paintHighlights measures untransformed cards.
      el.classList.add("flat");
      for (const card of el.querySelectorAll<HTMLElement>(".nc")) {
        const body = card.querySelector<HTMLElement>(".doc");
        if (body) paintHighlights(card, body);
      }
      el.classList.remove("flat");
    };
    paint();
    const resizeObserver = new ResizeObserver(paint);
    resizeObserver.observe(el);
    const stopRepainting = onHighlightRepaint(paint);
    return () => {
      resizeObserver.disconnect();
      stopRepainting();
    };
  }, [collage, samples]);
}

export function AuthShell({ children }: { children: React.ReactNode }) {
  const t = useTranslations();
  const locale = useLocale();
  const samples = React.useMemo(() => samplesFor(t, locale), [t, locale]);
  const collageRef = React.useRef<HTMLDivElement>(null);
  useCollageHighlights(collageRef, samples);
  return (
    <div className="grid min-h-dvh grid-cols-[minmax(0,1fr)_minmax(0,1.05fr)] bg-card max-lg:grid-cols-1">
      <main className="grid content-center justify-items-center overflow-auto p-8 max-md:content-start max-md:px-6 max-md:pt-12">
        <div className="grid w-[min(360px,100%)] gap-5">
          <Brand className="justify-self-start" />
          {children}
          <LanguageMenu placement="auth" />
        </div>
      </main>
      <Toaster />
      <div
        aria-hidden
        inert
        className="auth-art relative grid content-end overflow-hidden bg-sidebar p-10 max-lg:hidden"
      >
        <div
          ref={collageRef}
          className="collage absolute inset-x-0 top-0 bottom-27.5"
        >
          <div className="collage-stage">
            {samples.map((sample) => (
              <SampleCard key={sample.key} sample={sample} />
            ))}
          </div>
        </div>
        <div className="relative grid gap-1">
          <b className="font-bold font-serif text-[26px] leading-[1.2] tracking-[-.01em]">
            {t("authArtTitle")}
          </b>
          <span className="max-w-[40ch] text-muted-foreground text-ui">
            {t("authArtText")}
          </span>
        </div>
      </div>
    </div>
  );
}

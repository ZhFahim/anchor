import {
  EyeOff,
  Hourglass,
  KeyRound,
  Lock,
  type LucideIcon,
  UserRound,
} from "lucide-react";
import { cn } from "@/lib/utils";

export type StateIllustrationKind =
  | "missing"
  | "note"
  | "waiting"
  | "closed"
  | "callback"
  | "down"
  | "broken";

function Glyph({
  icon: Icon,
  x,
  y,
  size = 18,
  color = "var(--muted-foreground)",
}: {
  icon: LucideIcon;
  x: number;
  y: number;
  size?: number;
  color?: string;
}) {
  return (
    <Icon
      x={x}
      y={y}
      width={size}
      height={size}
      color={color}
      strokeWidth={2.2}
    />
  );
}

function Backdrop() {
  return (
    <>
      <circle
        cx="100"
        cy="72"
        r="68"
        fill="color-mix(in srgb, var(--muted-foreground) 7%, transparent)"
      />
      <g data-note="color_yellow">
        <rect
          x="34"
          y="28"
          width="62"
          height="76"
          rx="12"
          transform="rotate(-10 65 66)"
          fill="var(--note)"
          stroke="var(--note-border)"
        />
      </g>
      <g data-note="color_blue">
        <rect
          x="106"
          y="24"
          width="60"
          height="74"
          rx="12"
          transform="rotate(9 136 61)"
          fill="var(--note)"
          stroke="var(--note-border)"
        />
      </g>
    </>
  );
}

function Account({ active }: { active: boolean }) {
  return (
    <>
      <rect
        x="66"
        y="34"
        width="68"
        height="82"
        rx="13"
        fill="var(--card)"
        stroke="var(--border)"
      />
      <circle
        cx="100"
        cy="62"
        r="15"
        fill={active ? "var(--accent)" : "var(--muted)"}
      />
      <Glyph
        icon={UserRound}
        x={91}
        y={53}
        color={active ? "var(--card)" : "var(--muted-foreground)"}
      />
      <path
        d="M82 88h36M89 98h22"
        stroke="var(--border)"
        strokeWidth="3"
        strokeLinecap="round"
      />
      <circle
        cx="130"
        cy="106"
        r="17"
        fill="var(--card)"
        stroke="var(--border)"
      />
    </>
  );
}

export function StateIllustration({
  kind,
  className,
}: {
  kind: StateIllustrationKind;
  className?: string;
}) {
  return (
    <svg
      viewBox="0 0 200 144"
      aria-hidden
      className={cn(
        "h-auto drop-shadow-[0_18px_22px_color-mix(in_srgb,var(--foreground)_7%,transparent)]",
        className,
      )}
    >
      {kind === "down" ? (
        <>
          <circle
            cx="100"
            cy="72"
            r="68"
            fill="color-mix(in srgb, var(--muted-foreground) 7%, transparent)"
          />
          <rect
            x="24"
            y="44"
            width="58"
            height="42"
            rx="8"
            fill="var(--card)"
            stroke="var(--border)"
          />
          <path
            d="M16 94h74"
            stroke="var(--border)"
            strokeWidth="4"
            strokeLinecap="round"
          />
          <path
            d="M34 58h30M34 67h20"
            stroke="var(--muted)"
            strokeWidth="4"
            strokeLinecap="round"
          />
          <rect
            x="130"
            y="38"
            width="50"
            height="22"
            rx="7"
            fill="var(--card)"
            stroke="var(--border)"
          />
          <rect
            x="130"
            y="64"
            width="50"
            height="22"
            rx="7"
            fill="var(--card)"
            stroke="var(--border)"
          />
          <circle cx="142" cy="49" r="2.5" fill="var(--muted-foreground)" />
          <circle cx="142" cy="75" r="2.5" fill="var(--muted-foreground)" />
          <path
            d="M86 66h14M116 66h10"
            stroke="var(--muted-foreground)"
            strokeWidth="2"
            strokeDasharray="3 5"
            strokeLinecap="round"
          />
          <circle
            cx="108"
            cy="66"
            r="10"
            fill="var(--background)"
            stroke="var(--muted-foreground)"
            strokeWidth="1.6"
          />
          <path
            d="M104 62l8 8M112 62l-8 8"
            stroke="var(--muted-foreground)"
            strokeWidth="1.8"
            strokeLinecap="round"
          />
        </>
      ) : (
        <>
          <Backdrop />
          {kind === "missing" && (
            <>
              <rect
                x="66"
                y="34"
                width="68"
                height="82"
                rx="13"
                fill="var(--background)"
                stroke="var(--muted-foreground)"
                strokeWidth="1.6"
                strokeDasharray="6 5"
              />
              <text
                x="100"
                y="82"
                textAnchor="middle"
                fill="var(--muted-foreground)"
                style={{ font: "600 17px var(--font-mono)" }}
              >
                404
              </text>
            </>
          )}
          {kind === "note" && (
            <>
              <rect
                x="66"
                y="34"
                width="68"
                height="82"
                rx="13"
                fill="var(--card)"
                stroke="var(--border)"
              />
              <path
                d="M66 47a13 13 0 0 1 13-13h42a13 13 0 0 1 13 13v3H66z"
                fill="var(--muted)"
              />
              <path
                d="M78 66h44M78 76h32M78 86h38"
                stroke="var(--border)"
                strokeWidth="3"
                strokeLinecap="round"
              />
              <circle
                cx="130"
                cy="106"
                r="17"
                fill="var(--card)"
                stroke="var(--border)"
              />
              <Glyph icon={EyeOff} x={121} y={97} />
            </>
          )}
          {kind === "waiting" && (
            <>
              <Account active />
              <g className="hourglass-turn">
                <Glyph
                  icon={Hourglass}
                  x={121}
                  y={97}
                  color="var(--accent-strong)"
                />
              </g>
            </>
          )}
          {kind === "closed" && (
            <>
              <Account active={false} />
              <Glyph icon={Lock} x={121} y={97} />
            </>
          )}
          {kind === "callback" && (
            <>
              <Account active={false} />
              <Glyph icon={KeyRound} x={121} y={97} />
            </>
          )}
          {kind === "broken" && (
            <>
              <rect
                x="66"
                y="34"
                width="68"
                height="82"
                rx="13"
                fill="var(--card)"
                stroke="var(--border)"
              />
              <path
                d="M66 47a13 13 0 0 1 13-13h42a13 13 0 0 1 13 13v3H66z"
                fill="var(--accent)"
              />
              <path
                d="M78 66h44M78 76h32"
                stroke="var(--border)"
                strokeWidth="3"
                strokeLinecap="round"
              />
              <path
                d="M66 94l14-6 10 8 12-9 11 7 11-6 10 5"
                fill="none"
                stroke="var(--muted-foreground)"
                strokeWidth="1.8"
                strokeLinejoin="round"
                strokeLinecap="round"
              />
            </>
          )}
        </>
      )}
    </svg>
  );
}

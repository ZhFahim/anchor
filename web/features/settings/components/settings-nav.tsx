"use client";

import {
  HardDriveDownload,
  Info,
  KeyRound,
  Lock,
  PencilLine,
  SunMoon,
  UserRound,
} from "lucide-react";
import * as React from "react";
import { glidePill, prefersReducedMotion } from "@/lib/motion";
import { onUserScroll } from "@/lib/user-scroll";

const SECTIONS = [
  { id: "profile", label: "Profile", icon: UserRound },
  { id: "appearance", label: "Appearance", icon: SunMoon },
  { id: "editor", label: "Editor", icon: PencilLine },
  { id: "token", label: "API token", icon: KeyRound },
  { id: "data", label: "Import and export", icon: HardDriveDownload },
  { id: "password", label: "Password", icon: Lock },
  { id: "about", label: "About", icon: Info },
] as const;

export function SettingsNav() {
  const [activeSection, setActiveSection] = React.useState<string>(
    SECTIONS[0].id,
  );
  const activeSectionRef = React.useRef<string>(SECTIONS[0].id);
  const isClickedSectionHeldRef = React.useRef(false);

  const highlight = React.useCallback((id: string) => {
    const prev = activeSectionRef.current;
    if (prev === id) return;
    activeSectionRef.current = id;
    const nav = document.querySelector<HTMLElement>("[data-settings-nav]");
    const from = nav?.querySelector<HTMLElement>(`[data-go="${prev}"]`);
    const to = nav?.querySelector<HTMLElement>(`[data-go="${id}"]`);
    if (nav && from && to && window.matchMedia("(width >= 768px)").matches)
      glidePill(nav, from, to, "rounded-md bg-foreground/6");
    setActiveSection(id);
  }, []);

  React.useEffect(() => {
    const scroller = document.querySelector<HTMLElement>(
      `[data-slot="page-scroll"]`,
    );
    if (!scroller) return;
    const onScroll = () => {
      if (isClickedSectionHeldRef.current) return;
      const scrollerTop = scroller.getBoundingClientRect().top;
      let inView: string = SECTIONS[0].id;
      for (const section of SECTIONS) {
        const sectionEl = document.getElementById(`set-${section.id}`);
        if (
          sectionEl &&
          sectionEl.getBoundingClientRect().top - scrollerTop < 120
        )
          inView = section.id;
      }
      if (
        scroller.scrollTop + scroller.clientHeight >=
        scroller.scrollHeight - 4
      )
        inView = SECTIONS[SECTIONS.length - 1].id;
      highlight(inView);
    };
    scroller.addEventListener("scroll", onScroll, { passive: true });
    const stopWatching = onUserScroll(
      scroller,
      () => {
        isClickedSectionHeldRef.current = false;
      },
      "[data-settings-nav]",
    );
    return () => {
      scroller.removeEventListener("scroll", onScroll);
      stopWatching();
    };
  }, [highlight]);

  return (
    <nav
      data-settings-nav
      aria-label="Settings sections"
      className="sticky top-20 isolate grid gap-px max-md:static max-md:-mx-gutter-phone max-md:flex max-md:gap-1.5 max-md:overflow-x-auto max-md:px-gutter-phone max-md:scrollbar-none"
    >
      {SECTIONS.map((section) => (
        <a
          key={section.id}
          href={`#set-${section.id}`}
          data-go={section.id}
          aria-current={activeSection === section.id ? "location" : undefined}
          onClick={(e) => {
            e.preventDefault();
            isClickedSectionHeldRef.current = true;
            highlight(section.id);
            document.getElementById(`set-${section.id}`)?.scrollIntoView({
              behavior: prefersReducedMotion() ? "auto" : "smooth",
              block: "start",
            });
          }}
          className="relative flex h-8.5 items-center gap-2.5 rounded-md px-2.5 font-medium text-muted-foreground text-ui no-underline hover:bg-foreground/6 hover:text-foreground aria-[current=location]:bg-foreground/6 aria-[current=location]:font-semibold aria-[current=location]:text-foreground max-md:h-8 max-md:flex-none max-md:rounded-pill max-md:bg-muted max-md:px-3 [&>svg]:size-4 aria-[current=location]:[&>svg]:text-accent-strong max-md:[&>svg]:hidden"
        >
          <section.icon aria-hidden />
          {section.label}
        </a>
      ))}
    </nav>
  );
}

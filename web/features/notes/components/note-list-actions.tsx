"use client";

import { CircleCheck } from "lucide-react";
import { useTranslations } from "next-intl";
import type * as React from "react";
import { SearchField, TopBarButton } from "@/components/layout/app-page";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import type { NoteList } from "../hooks/use-note-list";
import { ViewOptions } from "./view-options";

export function NoteListActions({
  list,
  placeholder,
  autoFocus,
  onSearchFocus,
  children,
}: {
  list: NoteList;
  placeholder: string;
  autoFocus?: boolean;
  onSearchFocus?: () => void;
  children?: React.ReactNode;
}) {
  const t = useTranslations();
  return (
    <>
      <SearchField
        ref={list.searchRef}
        value={list.query}
        onChange={list.setQuery}
        placeholder={placeholder}
        autoFocus={autoFocus}
        onFocus={onSearchFocus}
        onBlur={list.flushQueryToUrl}
      />
      <ViewOptions
        layout={list.layout}
        sortBy={list.sortBy}
        sortOrder={list.sortOrder}
        onLayout={list.setLayout}
        onSort={list.setSort}
      />
      <TopBarButton
        icon={<CircleCheck aria-hidden />}
        aria-pressed={list.picking}
        onClick={list.togglePicking}
      >
        {t("notesSelectMode")}
      </TopBarButton>
      {children}
    </>
  );
}

export function NoSearchResults({ list }: { list: NoteList }) {
  const t = useTranslations();
  return (
    <EmptyState
      illustration="search"
      title={t("notesNoResultsTitle", { query: list.query.trim() })}
      action={
        <Button
          variant="secondary"
          onClick={() => {
            list.setQuery("");
            list.searchRef.current?.focus();
          }}
        >
          {t("notesClearSearch")}
        </Button>
      }
    >
      {t("notesNoResultsHelp")}
    </EmptyState>
  );
}

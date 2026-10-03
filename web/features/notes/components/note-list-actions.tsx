"use client";

import { CircleCheck } from "lucide-react";
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
  children,
}: {
  list: NoteList;
  placeholder: string;
  autoFocus?: boolean;
  children?: React.ReactNode;
}) {
  return (
    <>
      <SearchField
        ref={list.searchRef}
        value={list.query}
        onChange={list.setQuery}
        placeholder={placeholder}
        autoFocus={autoFocus}
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
        Select
      </TopBarButton>
      {children}
    </>
  );
}

export function NoSearchResults({ list }: { list: NoteList }) {
  return (
    <EmptyState
      illustration="search"
      title={`No results for “${list.query.trim()}”`}
      action={
        <Button
          variant="secondary"
          onClick={() => {
            list.setQuery("");
            list.searchRef.current?.focus();
          }}
        >
          Clear search
        </Button>
      }
    >
      Check the spelling or try different words.
    </EmptyState>
  );
}

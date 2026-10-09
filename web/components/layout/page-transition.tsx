"use client";

import { usePathname, useSearchParams } from "next/navigation";
import * as React from "react";
import { capturePage, type PageSnapshot, playPageChange } from "@/lib/morph";

interface PageSwapProps {
  pathname: string;
  tagId: string;
  children: React.ReactNode;
}

/** A tag in the address counts as its own page. */
export function PageTransition({ children }: { children: React.ReactNode }) {
  const pathname = usePathname() ?? "";
  const tagId = useSearchParams()?.get("tagId") ?? "";
  return (
    <PageSwap pathname={pathname} tagId={tagId}>
      {children}
    </PageSwap>
  );
}

// getSnapshotBeforeUpdate runs while the old page is still in the DOM.
class PageSwap extends React.Component<PageSwapProps> {
  private container = React.createRef<HTMLDivElement>();

  getSnapshotBeforeUpdate(previous: PageSwapProps): PageSnapshot | null {
    const { pathname, tagId } = this.props;
    const container = this.container.current;
    if (
      !container ||
      (previous.pathname === pathname && previous.tagId === tagId)
    )
      return null;
    return capturePage(container, previous.pathname, pathname);
  }

  componentDidUpdate(
    previous: PageSwapProps,
    _state: unknown,
    snapshot: PageSnapshot | null,
  ) {
    const container = this.container.current;
    if (!snapshot || !container) return;
    // A new note getting its id changes only the address.
    if (
      previous.pathname !== this.props.pathname &&
      snapshot.originals.every((element) => element.isConnected)
    )
      return;
    playPageChange(snapshot, container);
  }

  render() {
    return (
      <div ref={this.container} className="contents">
        {this.props.children}
      </div>
    );
  }
}

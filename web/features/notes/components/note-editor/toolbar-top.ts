export function toolbarTop(article: HTMLElement, isHeadHidden: boolean) {
  if (isHeadHidden) return 12;
  return (
    (article.querySelector<HTMLElement>(".ed-head")?.offsetHeight ?? 58) + 6
  );
}

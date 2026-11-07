export const QUERY_PARAM = "q";

export function urlWithQuery(pathname: string, search: string, query: string) {
  const params = new URLSearchParams(search);
  params.delete("search");
  if (query) params.set(QUERY_PARAM, query);
  else params.delete(QUERY_PARAM);
  const rest = params.toString();
  return rest ? `${pathname}?${rest}` : pathname;
}

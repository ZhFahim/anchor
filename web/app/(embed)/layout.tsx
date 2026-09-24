export default function EmbedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Chrome-less shell: the embedded MCP App renders inside the host's iframe,
  // so no app sidebar/header. It reuses the app's global styles/providers.
  return (
    <div className="min-h-0 bg-background text-foreground">{children}</div>
  );
}

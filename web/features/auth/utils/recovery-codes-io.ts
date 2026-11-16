import { recoveryCodesFile } from "./two-factor";

export function downloadRecoveryCodes(codes: readonly string[]): void {
  const url = URL.createObjectURL(
    new Blob([recoveryCodesFile(codes)], { type: "text/plain" }),
  );
  const link = document.createElement("a");
  link.href = url;
  link.download = "anchor-recovery-codes.txt";
  document.body.append(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}

/** Prints the codes from a throwaway frame, so nothing else on the page comes along. */
export function printRecoveryCodes(codes: readonly string[]): void {
  const frame = document.createElement("iframe");
  frame.setAttribute("aria-hidden", "true");
  frame.style.cssText =
    "position:fixed;inset:auto 0 0 auto;width:0;height:0;border:0;";
  document.body.append(frame);
  const doc = frame.contentDocument;
  const win = frame.contentWindow;
  if (!doc || !win) {
    frame.remove();
    return;
  }

  doc.title = "Anchor recovery codes";
  const style = doc.createElement("style");
  style.textContent =
    "body{font:16px system-ui,sans-serif;padding:32px}h1{font-size:20px}p{color:#444}" +
    "ul{list-style:none;padding:0;columns:2;font:18px ui-monospace,Menlo,monospace}li{margin:0 0 12px}";
  const heading = doc.createElement("h1");
  heading.textContent = "Anchor recovery codes";
  const note = doc.createElement("p");
  note.textContent = "Each code works once. Keep them somewhere safe.";
  const list = doc.createElement("ul");
  for (const code of codes) {
    const item = doc.createElement("li");
    item.textContent = code;
    list.append(item);
  }
  doc.head.append(style);
  doc.body.append(heading, note, list);

  win.addEventListener("afterprint", () => frame.remove(), { once: true });
  win.focus();
  win.print();
}

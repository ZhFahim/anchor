// Waves pattern: spacing = 40px, strokeWidth = 2px, starts at y = 20
// Uses quadratic bezier curves: Q(x+10, y-10, x+20, y) then Q(x+30, y+10, x+40, y)
export function WavesPattern({ color }: { color: string }) {
  const spacing = 40;
  const startY = 20;
  const waves = [];
  const rows = Math.ceil(3000 / spacing);

  for (let row = 0; row < rows; row++) {
    const y = startY + row * spacing;
    const path = [];
    path.push(`M 0 ${y}`);

    // Create wave pattern across width
    for (let x = 0; x < 3000; x += spacing) {
      path.push(`Q ${x + 10} ${y - 10} ${x + 20} ${y}`);
      path.push(`Q ${x + 30} ${y + 10} ${x + 40} ${y}`);
    }

    waves.push(
      <path
        key={row}
        d={path.join(" ")}
        fill="none"
        stroke={color}
        strokeWidth="2"
      />,
    );
  }

  return (
    <svg className="w-full h-full" xmlns="http://www.w3.org/2000/svg">
      {waves}
    </svg>
  );
}

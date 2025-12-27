import { ShoppingBag, Music, Plane, Code } from "lucide-react";

// Icon pattern: spacing = 60px, fontSize = 24px
export function IconPattern({
  icon: Icon,
  color,
  rotation = 0,
}: {
  icon: React.ComponentType<{ className?: string; size?: number }>;
  color: string;
  rotation?: number;
}) {
  const spacing = 60;
  const iconSize = 24;
  const startOffset = 20;

  // Calculate how many icons we need based on viewport
  // We'll render enough to cover a large area
  const cols = Math.ceil(3000 / spacing);
  const rows = Math.ceil(3000 / spacing);

  const icons = [];
  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      const offsetX = row % 2 === 0 ? 0 : spacing / 2;
      const x = startOffset + col * spacing + offsetX;
      const y = startOffset + row * spacing;
      icons.push(
        <div
          key={`${row}-${col}`}
          className="absolute"
          style={{
            left: `${x}px`,
            top: `${y}px`,
            transform: `translate(-50%, -50%) ${rotation !== 0 ? `rotate(${rotation * (180 / Math.PI)}deg)` : ""
              }`,
            color,
          }}
        >
          <Icon size={iconSize} className="[&_*]:stroke-current" />
        </div>
      );
    }
  }

  return <div className="relative w-full h-full">{icons}</div>;
}

// Icon pattern mappings
export const ICON_PATTERN_ICONS = {
  pattern_groceries: ShoppingBag,
  pattern_music: Music,
  pattern_travel: Plane,
  pattern_code: Code,
} as const;

export const ICON_PATTERN_ROTATIONS = {
  pattern_travel: 0.5,
} as const;

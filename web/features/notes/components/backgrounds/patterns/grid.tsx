// Grid pattern: spacing = 24px, strokeWidth = 1px
// Draws both vertical and horizontal lines
export function GridPattern({ color }: { color: string }) {
  return (
    <svg className="w-full h-full" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <pattern
          id="grid-pattern"
          x="0"
          y="0"
          width="24"
          height="24"
          patternUnits="userSpaceOnUse"
        >
          {/* Vertical line */}
          <line x1="0" y1="0" x2="0" y2="24" stroke={color} strokeWidth="1" />
          {/* Horizontal line */}
          <line x1="0" y1="0" x2="24" y2="0" stroke={color} strokeWidth="1" />
        </pattern>
      </defs>
      <rect width="100%" height="100%" fill="url(#grid-pattern)" />
    </svg>
  );
}

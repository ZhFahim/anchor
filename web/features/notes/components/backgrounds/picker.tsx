"use client";

import { Check, Palette } from "lucide-react";
import { useTheme } from "next-themes";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { ScrollArea } from "@/components/ui/scroll-area";
import { PATTERNS, SOLID_COLORS } from "@/features/notes/backgrounds";
import { cn } from "@/lib/utils";
import { NoteBackground } from "./background";

interface NoteBackgroundPickerProps {
  selectedBackground: string | null | undefined;
  onBackgroundChange: (background: string | null) => void;
  disabled?: boolean;
}

export function NoteBackgroundPicker({
  selectedBackground,
  onBackgroundChange,
  disabled = false,
}: NoteBackgroundPickerProps) {
  const [open, setOpen] = useState(false);
  const { theme, systemTheme } = useTheme();
  const resolvedTheme = theme === "system" ? systemTheme : theme;
  const isDark = resolvedTheme === "dark";

  const handleSelect = (styleId: string | null) => {
    onBackgroundChange(styleId);
    setOpen(false);
  };

  return (
    <Popover
      open={open && !disabled}
      onOpenChange={(open) => !disabled && setOpen(open)}
    >
      <PopoverTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className="h-9 w-9 rounded-xl"
          title="Change background"
          disabled={disabled}
        >
          <Palette className="h-4 w-4" />
        </Button>
      </PopoverTrigger>
      <PopoverContent
        className="w-96 p-0 shadow-lg border-border/40"
        align="end"
      >
        <div className="flex flex-col">
          {/* Header */}
          <div className="px-4 py-3 border-b border-border/40 bg-muted/30">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-accent/10 flex items-center justify-center">
                <Palette className="h-4 w-4 text-accent" />
              </div>
              <div>
                <h3 className="text-sm font-medium text-foreground">
                  Background
                </h3>
                <p className="text-xs text-muted-foreground">
                  Customize your note
                </p>
              </div>
            </div>
          </div>

          <ScrollArea className="max-h-[500px]">
            <div className="p-4 space-y-6">
              {/* Colors Section */}
              <div>
                <h4 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">
                  Color
                </h4>
                <div className="flex items-center gap-3 flex-wrap">
                  {/* None / Default option */}
                  <button
                    type="button"
                    onClick={() => handleSelect(null)}
                    className={cn(
                      "w-12 h-12 rounded-full border-2 transition-all duration-200",
                      "flex items-center justify-center",
                      "hover:scale-110 active:scale-95",
                      selectedBackground === null
                        ? "border-accent"
                        : "border-border/40 hover:border-border",
                    )}
                    style={{
                      backgroundColor: "var(--card)",
                    }}
                    title="Default"
                  >
                    {selectedBackground === null && (
                      <Check className="h-4 w-4 text-accent" />
                    )}
                  </button>

                  {/* Solid Colors */}
                  {SOLID_COLORS.map((style) => {
                    const isSelected = selectedBackground === style.id;
                    const backgroundColor = isDark
                      ? style.darkColor
                      : style.lightColor;
                    return (
                      <button
                        key={style.id}
                        type="button"
                        onClick={() => handleSelect(style.id)}
                        className={cn(
                          "w-12 h-12 rounded-full border-2 transition-all duration-200",
                          "flex items-center justify-center",
                          "hover:scale-110 active:scale-95",
                          isSelected
                            ? "border-accent"
                            : "border-transparent hover:border-border/60",
                        )}
                        style={{
                          backgroundColor,
                        }}
                        title={style.id.replace("color_", "").replace("_", " ")}
                      >
                        {isSelected && (
                          <Check
                            className="h-4 w-4"
                            style={{
                              color:
                                getLuminance(backgroundColor) > 0.5
                                  ? "#000"
                                  : "#fff",
                            }}
                          />
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Patterns Section */}
              <div>
                <h4 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">
                  Pattern
                </h4>
                <div className="flex items-center gap-3 flex-wrap">
                  {PATTERNS.map((style) => {
                    const isSelected = selectedBackground === style.id;
                    return (
                      <button
                        key={style.id}
                        type="button"
                        onClick={() => handleSelect(style.id)}
                        className={cn(
                          "w-12 h-12 rounded-lg border-2 transition-all duration-200 overflow-hidden",
                          "flex items-center justify-center relative",
                          "hover:scale-110 active:scale-95",
                          isSelected
                            ? "border-accent"
                            : "border-border/40 hover:border-border",
                        )}
                        title={style.id
                          .replace("pattern_", "")
                          .replace("_", " ")}
                      >
                        <NoteBackground
                          styleId={style.id}
                          className="absolute inset-0"
                        />
                        {isSelected && (
                          <div className="relative z-10 w-5 h-5 rounded-full bg-white/80 flex items-center justify-center">
                            <Check className="h-3 w-3 text-black" />
                          </div>
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>
          </ScrollArea>
        </div>
      </PopoverContent>
    </Popover>
  );
}

// Helper function to calculate luminance
function getLuminance(hex: string): number {
  const rgb = hexToRgb(hex);
  if (!rgb) return 0;
  const [r, g, b] = rgb.map((val) => {
    val = val / 255;
    return val <= 0.03928 ? val / 12.92 : ((val + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function hexToRgb(hex: string): [number, number, number] | null {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result
    ? [
        parseInt(result[1], 16),
        parseInt(result[2], 16),
        parseInt(result[3], 16),
      ]
    : null;
}

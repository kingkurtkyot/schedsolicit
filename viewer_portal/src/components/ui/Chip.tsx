'use client';

import React from 'react';
import { cn } from '@/lib/utils';
import { X } from 'lucide-react';

export interface ChipProps extends React.HTMLAttributes<HTMLSpanElement> {
  label: string;
  color?: string; // hex color for custom background / border
  icon?: React.ReactNode;
  selected?: boolean;
  removable?: boolean;
  onRemove?: (e: React.MouseEvent) => void;
  onClick?: (e: React.MouseEvent) => void;
}

export const Chip: React.FC<ChipProps> = ({
  label,
  color,
  icon,
  selected = false,
  removable = false,
  onRemove,
  onClick,
  className,
  ...props
}) => {
  const isInteractive = Boolean(onClick);

  // Generate dynamic styles for colored chips matching status_definitions
  const customStyle: React.CSSProperties = color
    ? {
        backgroundColor: `${color}1A`, // 10% opacity background
        borderColor: `${color}66`, // 40% opacity border
        color: color,
      }
    : {};

  return (
    <span
      role={isInteractive ? 'button' : undefined}
      tabIndex={isInteractive ? 0 : undefined}
      onClick={onClick}
      onKeyDown={(e) => {
        if (isInteractive && (e.key === 'Enter' || e.key === ' ')) {
          e.preventDefault();
          onClick?.(e as any);
        }
      }}
      style={customStyle}
      className={cn(
        'inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-medium rounded-full border transition-all duration-150',
        !color && [
          selected
            ? 'bg-[var(--color-seed)] text-[var(--text-on-brand)] border-[var(--color-seed)] shadow-sm'
            : 'bg-[var(--surface-container)] text-[var(--text-secondary)] border-[var(--surface-border-subtle)]',
        ],
        isInteractive && 'cursor-pointer active:scale-95 touch:min-h-[32px]',
        className
      )}
      {...props}
    >
      {icon && <span className="flex-shrink-0 text-current">{icon}</span>}
      <span className="truncate max-w-[180px]">{label}</span>
      {removable && (
        <button
          type="button"
          aria-label={`Remove filter ${label}`}
          onClick={(e) => {
            e.stopPropagation();
            onRemove?.(e);
          }}
          className="ml-0.5 -mr-1 p-0.5 rounded-full hover:bg-black/10 dark:hover:bg-white/10 active:scale-90 transition-transform"
        >
          <X className="w-3 h-3" />
        </button>
      )}
    </span>
  );
};

'use client';

import React from 'react';
import { cn } from '@/lib/utils';
import { ShieldCheck, RefreshCw } from 'lucide-react';

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: 'count' | 'viewOnly' | 'updated' | 'priority' | 'status';
  count?: number;
  label?: string;
  color?: string;
  pulsing?: boolean;
}

export const Badge: React.FC<BadgeProps> = ({
  variant = 'count',
  count,
  label,
  color,
  pulsing = false,
  className,
  ...props
}) => {
  if (variant === 'viewOnly') {
    return (
      <span
        className={cn(
          'inline-flex items-center gap-1 px-2.5 py-0.5 text-[11px] font-semibold tracking-wide uppercase rounded-full',
          'bg-[var(--surface-container)] text-[var(--text-muted)] border border-[var(--surface-border)] shadow-xs',
          className
        )}
        {...props}
      >
        <ShieldCheck className="w-3.5 h-3.5 text-[var(--color-seed)]" />
        <span>View only</span>
      </span>
    );
  }

  if (variant === 'updated') {
    return (
      <span
        className={cn(
          'inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-medium rounded-full transition-all duration-300',
          'bg-emerald-100 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300 border border-emerald-300 dark:border-emerald-800',
          pulsing && 'animate-pulse scale-105',
          className
        )}
        {...props}
      >
        <RefreshCw className={cn('w-3 h-3', pulsing && 'animate-spin')} />
        <span>Updated</span>
      </span>
    );
  }

  if (variant === 'count') {
    return (
      <span
        className={cn(
          'inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 text-[11px] font-bold rounded-full',
          'bg-[var(--color-seed)] text-[var(--text-on-brand)] shadow-xs',
          className
        )}
        {...props}
      >
        {count != null ? (count > 99 ? '99+' : count) : label}
      </span>
    );
  }

  return (
    <span
      style={color ? { backgroundColor: `${color}20`, color, borderColor: `${color}40` } : undefined}
      className={cn(
        'inline-flex items-center px-2 py-0.5 text-xs font-semibold rounded border',
        !color && 'bg-[var(--surface-container)] text-[var(--text-secondary)] border-[var(--surface-border)]',
        className
      )}
      {...props}
    >
      {label || count}
    </span>
  );
};

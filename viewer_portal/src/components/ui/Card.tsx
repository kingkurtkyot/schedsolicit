'use client';

import React from 'react';
import { cn } from '@/lib/utils';

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'container' | 'bordered';
  mode?: 'compact' | 'expanded';
  interactive?: boolean;
}

export const Card = React.forwardRef<HTMLDivElement, CardProps>(
  ({ className, variant = 'default', mode = 'compact', interactive = false, children, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn(
          'rounded-xl transition-all duration-200 overflow-hidden',
          // Surfaces
          variant === 'default' &&
            'bg-[var(--surface-card)] border border-[var(--surface-border-subtle)] shadow-[var(--shadow-low)]',
          variant === 'container' &&
            'bg-[var(--surface-container)] border border-transparent',
          variant === 'bordered' &&
            'bg-transparent border border-[var(--surface-border)]',
          // Mode padding
          mode === 'compact' ? 'p-3.5 sm:p-4' : 'p-5 sm:p-6',
          // Interactivity (tap target & hover)
          interactive && [
            'cursor-pointer active:scale-[0.985] active:brightness-95',
            'desktop:hover:shadow-[var(--shadow-medium)] desktop:hover:border-[var(--color-seed)]',
            'touch:min-h-[44px]',
          ],
          className
        )}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Card.displayName = 'Card';

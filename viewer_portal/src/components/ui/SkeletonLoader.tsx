import React from 'react';
import { cn } from '@/lib/utils';

interface SkeletonProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: 'card' | 'detail' | 'calendar' | 'line';
  count?: number;
}

export const SkeletonLoader: React.FC<SkeletonProps> = ({
  variant = 'card',
  count = 1,
  className,
}) => {
  const renderItem = (index: number) => {
    if (variant === 'line') {
      return (
        <div
          key={index}
          className={cn(
            'h-4 w-full rounded bg-gray-200 dark:bg-gray-800 animate-pulse',
            className
          )}
        />
      );
    }

    if (variant === 'card') {
      return (
        <div
          key={index}
          className="p-4 rounded-xl border border-[var(--surface-border-subtle)] bg-[var(--surface-card)] shadow-xs space-y-3"
        >
          <div className="flex items-center justify-between gap-2">
            <div className="h-5 w-3/5 rounded bg-gray-200 dark:bg-gray-800 animate-pulse" />
            <div className="h-5 w-16 rounded-full bg-gray-200 dark:bg-gray-800 animate-pulse" />
          </div>
          <div className="h-3.5 w-2/5 rounded bg-gray-200 dark:bg-gray-800 animate-pulse" />
          <div className="flex items-center gap-2 pt-1">
            <div className="h-6 w-20 rounded-full bg-gray-200 dark:bg-gray-800 animate-pulse" />
            <div className="h-6 w-24 rounded-full bg-gray-200 dark:bg-gray-800 animate-pulse" />
          </div>
        </div>
      );
    }

    if (variant === 'calendar') {
      return (
        <div key={index} className="grid grid-cols-7 gap-1 p-2">
          {Array.from({ length: 35 }).map((_, i) => (
            <div
              key={i}
              className="h-20 rounded-lg bg-gray-100 dark:bg-gray-800/40 p-1 flex flex-col justify-between animate-pulse"
            >
              <div className="h-3 w-4 rounded bg-gray-200 dark:bg-gray-700" />
              <div className="h-2 w-8 rounded-full bg-gray-200 dark:bg-gray-700" />
            </div>
          ))}
        </div>
      );
    }

    if (variant === 'detail') {
      return (
        <div key={index} className="p-6 rounded-2xl bg-[var(--surface-card)] space-y-6">
          <div className="space-y-2">
            <div className="h-4 w-24 rounded bg-gray-200 dark:bg-gray-800 animate-pulse" />
            <div className="h-8 w-3/4 rounded bg-gray-200 dark:bg-gray-800 animate-pulse" />
          </div>
          <div className="h-24 w-full rounded-xl bg-gray-200 dark:bg-gray-800 animate-pulse" />
          <div className="grid grid-cols-2 gap-4">
            <div className="h-16 rounded-xl bg-gray-200 dark:bg-gray-800 animate-pulse" />
            <div className="h-16 rounded-xl bg-gray-200 dark:bg-gray-800 animate-pulse" />
          </div>
        </div>
      );
    }

    return null;
  };

  return (
    <div className={cn('space-y-3 w-full', className)}>
      {Array.from({ length: count }).map((_, i) => renderItem(i))}
    </div>
  );
};

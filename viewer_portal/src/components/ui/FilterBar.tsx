'use client';

import React from 'react';
import { FilterState, Priority } from '@/lib/types';
import { Chip } from './Chip';
import { SlidersHorizontal, Trash2 } from 'lucide-react';
import { cn } from '@/lib/utils';

interface FilterBarProps {
  filters: FilterState;
  activeCount: number;
  totalResults?: number;
  onOpenFilterSheet: () => void;
  onRemoveCategory: (cat: string) => void;
  onRemoveStatus: (status: string) => void;
  onRemovePriority: (p: Priority) => void;
  onClearDateRange: () => void;
  onClearAll: () => void;
  className?: string;
}

export const FilterBar: React.FC<FilterBarProps> = ({
  filters,
  activeCount,
  totalResults,
  onOpenFilterSheet,
  onRemoveCategory,
  onRemoveStatus,
  onRemovePriority,
  onClearDateRange,
  onClearAll,
  className,
}) => {
  return (
    <div
      className={cn(
        'sticky top-0 z-20 flex items-center gap-2 py-2.5 px-4 bg-[var(--surface-bg)]/90 backdrop-blur-md border-b border-[var(--surface-border-subtle)] overflow-x-auto no-scrollbar',
        className
      )}
    >
      {/* Filter panel trigger */}
      <button
        type="button"
        onClick={onOpenFilterSheet}
        className={cn(
          'flex-shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all shadow-xs',
          'bg-[var(--surface-card)] text-[var(--text-primary)] border border-[var(--surface-border)]',
          'hover:border-[var(--color-seed)] active:scale-95 touch:min-h-[44px]'
        )}
      >
        <SlidersHorizontal className="w-3.5 h-3.5 text-[var(--color-seed)]" />
        <span>Filters</span>
        {activeCount > 0 && (
          <span className="inline-flex items-center justify-center w-4 h-4 text-[10px] font-bold rounded-full bg-[var(--color-seed)] text-white">
            {activeCount}
          </span>
        )}
      </button>

      {/* Result count badge */}
      {totalResults != null && (
        <span className="flex-shrink-0 text-xs font-medium text-[var(--text-muted)] px-1">
          {totalResults} items
        </span>
      )}

      {/* Active Filter Chips */}
      <div className="flex items-center gap-1.5 flex-nowrap">
        {filters.categories.map((cat) => (
          <Chip
            key={`cat-${cat}`}
            label={cat}
            removable
            onRemove={() => onRemoveCategory(cat)}
          />
        ))}

        {filters.statuses.map((st) => (
          <Chip
            key={`st-${st}`}
            label={st}
            removable
            onRemove={() => onRemoveStatus(st)}
          />
        ))}

        {filters.priorities.map((pr) => (
          <Chip
            key={`pr-${pr}`}
            label={`${pr} priority`}
            removable
            onRemove={() => onRemovePriority(pr)}
          />
        ))}

        {filters.dateRange && (filters.dateRange.from || filters.dateRange.to) && (
          <Chip
            label="Date Range"
            removable
            onRemove={onClearDateRange}
          />
        )}
      </div>

      {/* Clear all button */}
      {activeCount > 0 && (
        <button
          type="button"
          onClick={onClearAll}
          className="flex-shrink-0 flex items-center gap-1 ml-auto text-xs font-medium text-[var(--text-muted)] hover:text-red-500 active:scale-95 px-2 py-1"
        >
          <Trash2 className="w-3 h-3" />
          <span>Clear</span>
        </button>
      )}
    </div>
  );
};

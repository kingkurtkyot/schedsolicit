'use client';

import React from 'react';
import { FilterState, Priority, TimeFilterMode } from '@/lib/types';
import { Chip } from './Chip';
import { SlidersHorizontal, Trash2, ChevronLeft, ChevronRight, Calendar as CalendarIcon } from 'lucide-react';
import { cn } from '@/lib/utils';

interface FilterBarProps {
  filters: FilterState;
  activeCount: number;
  totalResults?: number;
  onOpenFilterSheet: () => void;
  onSetTimeMode?: (mode: TimeFilterMode) => void;
  onPreviousStep?: () => void;
  onNextStep?: () => void;
  onJumpToToday?: () => void;
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
  onSetTimeMode,
  onPreviousStep,
  onNextStep,
  onJumpToToday,
  onRemoveCategory,
  onRemoveStatus,
  onRemovePriority,
  onClearDateRange,
  onClearAll,
  className,
}) => {
  const timeMode = filters.timeMode || 'all';
  const anchor = filters.timeAnchor ? new Date(filters.timeAnchor) : new Date();

  // Helper formatting for anchor
  const formatAnchor = () => {
    const now = new Date();
    const isSameDay = anchor.toDateString() === now.toDateString();
    const isSameMonth = anchor.getFullYear() === now.getFullYear() && anchor.getMonth() === now.getMonth();
    const isSameYear = anchor.getFullYear() === now.getFullYear();

    if (timeMode === 'day') {
      const formatted = anchor.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' });
      return isSameDay ? `Today • ${formatted}` : formatted;
    }
    if (timeMode === 'month') {
      const formatted = anchor.toLocaleDateString(undefined, { month: 'long', year: 'numeric' });
      return isSameMonth ? `This Month • ${formatted}` : formatted;
    }
    if (timeMode === 'year') {
      const formatted = `${anchor.getFullYear()}`;
      return isSameYear ? `This Year • ${formatted}` : formatted;
    }
    return 'All Dates';
  };

  const isCurrent = () => {
    const now = new Date();
    if (timeMode === 'day') return anchor.toDateString() === now.toDateString();
    if (timeMode === 'month') return anchor.getFullYear() === now.getFullYear() && anchor.getMonth() === now.getMonth();
    if (timeMode === 'year') return anchor.getFullYear() === now.getFullYear();
    return true;
  };

  return (
    <div className={cn('space-y-2 py-2', className)}>
      {/* 1. Time Navigation Header (Day / Month / Year) */}
      <div className="flex flex-wrap items-center justify-between gap-2 px-2 sm:px-0">
        {/* Time Mode Pills */}
        <div className="inline-flex items-center p-0.5 rounded-xl bg-[var(--surface-container)] border border-[var(--surface-border-subtle)]">
          {(['all', 'day', 'month', 'year'] as TimeFilterMode[]).map((mode) => (
            <button
              key={mode}
              type="button"
              onClick={() => onSetTimeMode?.(mode)}
              className={cn(
                'px-3 py-1 text-xs font-semibold rounded-lg capitalize transition-all min-h-[30px]',
                timeMode === mode
                  ? 'bg-[var(--surface-card)] text-[var(--color-seed)] shadow-xs'
                  : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
              )}
            >
              {mode}
            </button>
          ))}
        </div>

        {/* Stepper Navigation (Active when day, month, or year selected) */}
        {timeMode !== 'all' && (
          <div className="flex items-center gap-1.5 p-1 rounded-xl bg-[var(--surface-container)] border border-[var(--surface-border-subtle)]">
            <button
              type="button"
              onClick={onPreviousStep}
              className="p-1 rounded-lg text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--surface-card)] active:scale-95"
              title="Previous"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>

            <span className="flex items-center gap-1 px-2 text-xs font-bold text-[var(--color-seed)]">
              <CalendarIcon className="w-3.5 h-3.5" />
              <span>{formatAnchor()}</span>
            </span>

            {!isCurrent() && (
              <button
                type="button"
                onClick={onJumpToToday}
                className="px-2 py-0.5 text-[11px] font-bold rounded-md bg-[var(--color-seed)]/10 text-[var(--color-seed)] hover:bg-[var(--color-seed)]/20 active:scale-95"
              >
                Today
              </button>
            )}

            <button
              type="button"
              onClick={onNextStep}
              className="p-1 rounded-lg text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--surface-card)] active:scale-95"
              title="Next"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        )}
      </div>

      {/* 2. Filter Bar with Chips */}
      <div className="flex items-center gap-2 px-1 overflow-x-auto no-scrollbar">
        {/* Filter panel trigger */}
        <button
          type="button"
          onClick={onOpenFilterSheet}
          className={cn(
            'flex-shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all shadow-xs',
            'bg-[var(--surface-card)] text-[var(--text-primary)] border border-[var(--surface-border)]',
            'hover:border-[var(--color-seed)] active:scale-95 touch:min-h-[36px]'
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

        {/* Result count */}
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

          {timeMode === 'custom' && filters.dateRange && (filters.dateRange.from || filters.dateRange.to) && (
            <Chip
              label="Custom Date Range"
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
    </div>
  );
};

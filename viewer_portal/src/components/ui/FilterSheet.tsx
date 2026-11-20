'use client';

import React from 'react';
import { FilterState, Priority } from '@/lib/types';
import { X, SlidersHorizontal, Check } from 'lucide-react';
import { cn } from '@/lib/utils';

interface FilterSheetProps {
  isOpen: boolean;
  onClose: () => void;
  filters: FilterState;
  onApplyFilters: (newFilters: FilterState) => void;
  availableCategories?: string[];
  availableStatuses?: string[];
}

export const FilterSheet: React.FC<FilterSheetProps> = ({
  isOpen,
  onClose,
  filters,
  onApplyFilters,
  availableCategories = ['General', 'Meeting', 'Sponsorship', 'Donation', 'Grant', 'Equipment'],
  availableStatuses = ['Active', 'Pending', 'Done', 'Approved', 'Declined', 'Given', 'Draft'],
}) => {
  const [localFilters, setLocalFilters] = React.useState<FilterState>(filters);

  React.useEffect(() => {
    setLocalFilters(filters);
  }, [filters, isOpen]);

  if (!isOpen) return null;

  const toggleCategory = (cat: string) => {
    setLocalFilters((prev) => {
      const exists = prev.categories.includes(cat);
      return {
        ...prev,
        categories: exists ? prev.categories.filter((c) => c !== cat) : [...prev.categories, cat],
      };
    });
  };

  const toggleStatus = (st: string) => {
    setLocalFilters((prev) => {
      const exists = prev.statuses.includes(st);
      return {
        ...prev,
        statuses: exists ? prev.statuses.filter((s) => s !== st) : [...prev.statuses, st],
      };
    });
  };

  const togglePriority = (pr: Priority) => {
    setLocalFilters((prev) => {
      const exists = prev.priorities.includes(pr);
      return {
        ...prev,
        priorities: exists ? prev.priorities.filter((p) => p !== pr) : [...prev.priorities, pr],
      };
    });
  };

  const handleApply = () => {
    onApplyFilters(localFilters);
    onClose();
  };

  const handleReset = () => {
    const cleared: FilterState = {
      search: '',
      categories: [],
      statuses: [],
      priorities: [],
    };
    setLocalFilters(cleared);
    onApplyFilters(cleared);
    onClose();
  };

  const priorities: Priority[] = ['urgent', 'high', 'medium', 'low'];

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/40 backdrop-blur-xs transition-opacity">
      <div
        className={cn(
          'w-full max-w-md h-full bg-[var(--surface-card)] flex flex-col',
          'border-l border-[var(--surface-border-subtle)] shadow-2xl',
          'overflow-y-auto pb-[env(safe-area-inset-bottom,16px)]'
        )}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-[var(--surface-border-subtle)] sticky top-0 bg-[var(--surface-card)] z-10">
          <div className="flex items-center gap-2">
            <SlidersHorizontal className="w-5 h-5 text-[var(--color-seed)]" />
            <h2 className="text-base font-bold text-[var(--text-primary)]">Filters</h2>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close filters"
            className="p-2 rounded-full hover:bg-[var(--surface-container)] text-[var(--text-muted)] touch:min-h-[44px] touch:min-w-[44px] flex items-center justify-center"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Filter Sections */}
        <div className="p-5 space-y-6 flex-1">
          {/* Priorities */}
          <div className="space-y-2.5">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)]">
              Priority
            </h3>
            <div className="grid grid-cols-2 gap-2">
              {priorities.map((pr) => {
                const isSelected = localFilters.priorities.includes(pr);
                return (
                  <button
                    key={pr}
                    type="button"
                    onClick={() => togglePriority(pr)}
                    className={cn(
                      'flex items-center justify-between px-3 py-2 rounded-xl text-xs font-semibold border transition-all min-h-[44px]',
                      isSelected
                        ? 'bg-[var(--color-seed)] text-white border-[var(--color-seed)] shadow-xs'
                        : 'bg-[var(--surface-container)] text-[var(--text-secondary)] border-[var(--surface-border-subtle)]'
                    )}
                  >
                    <span className="capitalize">{pr}</span>
                    {isSelected && <Check className="w-4 h-4" />}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Categories */}
          <div className="space-y-2.5">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)]">
              Category
            </h3>
            <div className="flex flex-wrap gap-2">
              {availableCategories.map((cat) => {
                const isSelected = localFilters.categories.includes(cat);
                return (
                  <button
                    key={cat}
                    type="button"
                    onClick={() => toggleCategory(cat)}
                    className={cn(
                      'px-3 py-1.5 rounded-full text-xs font-medium border transition-all min-h-[36px] touch:min-h-[44px]',
                      isSelected
                        ? 'bg-[var(--color-seed)] text-white border-[var(--color-seed)] shadow-xs'
                        : 'bg-[var(--surface-container)] text-[var(--text-secondary)] border-[var(--surface-border-subtle)]'
                    )}
                  >
                    {cat}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Statuses */}
          <div className="space-y-2.5">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)]">
              Status
            </h3>
            <div className="flex flex-wrap gap-2">
              {availableStatuses.map((st) => {
                const isSelected = localFilters.statuses.includes(st);
                return (
                  <button
                    key={st}
                    type="button"
                    onClick={() => toggleStatus(st)}
                    className={cn(
                      'px-3 py-1.5 rounded-full text-xs font-medium border transition-all min-h-[36px] touch:min-h-[44px]',
                      isSelected
                        ? 'bg-[var(--color-seed)] text-white border-[var(--color-seed)] shadow-xs'
                        : 'bg-[var(--surface-container)] text-[var(--text-secondary)] border-[var(--surface-border-subtle)]'
                    )}
                  >
                    {st}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Date Range */}
          <div className="space-y-2.5">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)]">
              Date Range
            </h3>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="text-[11px] text-[var(--text-muted)] block mb-1">From</label>
                <input
                  type="date"
                  value={localFilters.dateRange?.from || ''}
                  onChange={(e) =>
                    setLocalFilters((prev) => ({
                      ...prev,
                      dateRange: { ...prev.dateRange, from: e.target.value },
                    }))
                  }
                  className="w-full px-2.5 py-2 rounded-xl text-base sm:text-xs bg-[var(--surface-container)] border border-[var(--surface-border-subtle)] min-h-[44px]"
                />
              </div>
              <div>
                <label className="text-[11px] text-[var(--text-muted)] block mb-1">To</label>
                <input
                  type="date"
                  value={localFilters.dateRange?.to || ''}
                  onChange={(e) =>
                    setLocalFilters((prev) => ({
                      ...prev,
                      dateRange: { ...prev.dateRange, to: e.target.value },
                    }))
                  }
                  className="w-full px-2.5 py-2 rounded-xl text-base sm:text-xs bg-[var(--surface-container)] border border-[var(--surface-border-subtle)] min-h-[44px]"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="p-4 border-t border-[var(--surface-border-subtle)] bg-[var(--surface-card)] flex items-center gap-3">
          <button
            type="button"
            onClick={handleReset}
            className="flex-1 py-3 px-4 rounded-xl text-xs font-semibold text-[var(--text-secondary)] bg-[var(--surface-container)] hover:bg-[var(--surface-border-subtle)] active:scale-95 min-h-[44px]"
          >
            Reset
          </button>
          <button
            type="button"
            onClick={handleApply}
            className="flex-1 py-3 px-4 rounded-xl text-xs font-semibold text-white bg-[var(--color-seed)] hover:bg-[var(--color-forest)] active:scale-95 shadow-xs min-h-[44px]"
          >
            Apply Filters
          </button>
        </div>
      </div>
    </div>
  );
};

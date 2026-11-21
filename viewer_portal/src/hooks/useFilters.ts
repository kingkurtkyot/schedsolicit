'use client';

import { useState, useCallback, useMemo, useEffect } from 'react';
import { FilterState, GroupBy, Priority, SortState, TimeFilterMode } from '@/lib/types';

const STORAGE_KEY = 'schedsolicit_filter_presets';

function computeDateRange(mode: TimeFilterMode, anchor: Date): { from?: string; to?: string } | undefined {
  if (mode === 'all') return undefined;

  const y = anchor.getFullYear();
  const m = anchor.getMonth();
  const d = anchor.getDate();

  if (mode === 'day') {
    const from = new Date(y, m, d, 0, 0, 0, 0).toISOString();
    const to = new Date(y, m, d, 23, 59, 59, 999).toISOString();
    return { from, to };
  }

  if (mode === 'month') {
    const from = new Date(y, m, 1, 0, 0, 0, 0).toISOString();
    const lastDay = new Date(y, m + 1, 0).getDate();
    const to = new Date(y, m, lastDay, 23, 59, 59, 999).toISOString();
    return { from, to };
  }

  if (mode === 'year') {
    const from = new Date(y, 0, 1, 0, 0, 0, 0).toISOString();
    const to = new Date(y, 11, 31, 23, 59, 59, 999).toISOString();
    return { from, to };
  }

  return undefined;
}

export function useFilters() {
  const [filters, setFilters] = useState<FilterState>({
    search: '',
    categories: [],
    statuses: [],
    priorities: [],
    timeMode: 'all',
    timeAnchor: new Date().toISOString(),
  });

  const [sort, setSort] = useState<SortState>({
    field: 'date',
    direction: 'asc',
  });

  const [groupBy, setGroupBy] = useState<GroupBy>('date');

  // Load presets from localStorage
  const [presets, setPresets] = useState<Array<{ name: string; filters: FilterState }>>([]);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      try {
        const stored = localStorage.getItem(STORAGE_KEY);
        if (stored) {
          setPresets(JSON.parse(stored));
        }
      } catch {
        // ignore
      }
    }
  }, []);

  const activeFilterCount = useMemo(() => {
    let count = 0;
    if (filters.search) count++;
    if (filters.timeMode && filters.timeMode !== 'all') count++;
    count += filters.categories.length;
    count += filters.statuses.length;
    count += filters.priorities.length;
    if (filters.dateRange?.from || filters.dateRange?.to) count++;
    if (filters.dayOfWeek && filters.dayOfWeek.length > 0) count++;
    if (filters.onlyOverdue) count++;
    return count;
  }, [filters]);

  const setSearch = useCallback((search: string) => {
    setFilters((prev) => ({ ...prev, search }));
  }, []);

  const setTimeMode = useCallback((mode: TimeFilterMode, anchor?: Date) => {
    setFilters((prev) => {
      const targetAnchor = anchor || (prev.timeAnchor ? new Date(prev.timeAnchor) : new Date());
      const dateRange = computeDateRange(mode, targetAnchor);
      return {
        ...prev,
        timeMode: mode,
        timeAnchor: targetAnchor.toISOString(),
        dateRange,
      };
    });
  }, []);

  const previousTimeStep = useCallback(() => {
    setFilters((prev) => {
      const mode = prev.timeMode || 'all';
      if (mode === 'all') return prev;

      const current = prev.timeAnchor ? new Date(prev.timeAnchor) : new Date();
      let nextAnchor = new Date(current);

      if (mode === 'day') {
        nextAnchor.setDate(current.getDate() - 1);
      } else if (mode === 'month') {
        nextAnchor.setMonth(current.getMonth() - 1);
      } else if (mode === 'year') {
        nextAnchor.setFullYear(current.getFullYear() - 1);
      }

      const dateRange = computeDateRange(mode, nextAnchor);
      return {
        ...prev,
        timeAnchor: nextAnchor.toISOString(),
        dateRange,
      };
    });
  }, []);

  const nextTimeStep = useCallback(() => {
    setFilters((prev) => {
      const mode = prev.timeMode || 'all';
      if (mode === 'all') return prev;

      const current = prev.timeAnchor ? new Date(prev.timeAnchor) : new Date();
      let nextAnchor = new Date(current);

      if (mode === 'day') {
        nextAnchor.setDate(current.getDate() + 1);
      } else if (mode === 'month') {
        nextAnchor.setMonth(current.getMonth() + 1);
      } else if (mode === 'year') {
        nextAnchor.setFullYear(current.getFullYear() + 1);
      }

      const dateRange = computeDateRange(mode, nextAnchor);
      return {
        ...prev,
        timeAnchor: nextAnchor.toISOString(),
        dateRange,
      };
    });
  }, []);

  const jumpToToday = useCallback(() => {
    setFilters((prev) => {
      const mode = prev.timeMode === 'all' ? 'day' : prev.timeMode || 'day';
      const today = new Date();
      const dateRange = computeDateRange(mode, today);
      return {
        ...prev,
        timeMode: mode,
        timeAnchor: today.toISOString(),
        dateRange,
      };
    });
  }, []);

  const toggleCategory = useCallback((category: string) => {
    setFilters((prev) => {
      const exists = prev.categories.includes(category);
      return {
        ...prev,
        categories: exists
          ? prev.categories.filter((c) => c !== category)
          : [...prev.categories, category],
      };
    });
  }, []);

  const toggleStatus = useCallback((status: string) => {
    setFilters((prev) => {
      const exists = prev.statuses.includes(status);
      return {
        ...prev,
        statuses: exists
          ? prev.statuses.filter((s) => s !== status)
          : [...prev.statuses, status],
      };
    });
  }, []);

  const togglePriority = useCallback((priority: Priority) => {
    setFilters((prev) => {
      const exists = prev.priorities.includes(priority);
      return {
        ...prev,
        priorities: exists
          ? prev.priorities.filter((p) => p !== priority)
          : [...prev.priorities, priority],
      };
    });
  }, []);

  const setDateRange = useCallback((from?: string, to?: string) => {
    setFilters((prev) => ({
      ...prev,
      timeMode: from || to ? 'custom' : 'all',
      dateRange: from || to ? { from, to } : undefined,
    }));
  }, []);

  const setOnlyOverdue = useCallback((onlyOverdue: boolean) => {
    setFilters((prev) => ({ ...prev, onlyOverdue }));
  }, []);

  const clearAll = useCallback(() => {
    setFilters({
      search: '',
      categories: [],
      statuses: [],
      priorities: [],
      timeMode: 'all',
      timeAnchor: new Date().toISOString(),
      dateRange: undefined,
    });
  }, []);

  const savePreset = useCallback(
    (name: string) => {
      const newPresets = [...presets, { name, filters }];
      setPresets(newPresets);
      if (typeof window !== 'undefined') {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(newPresets));
      }
    },
    [presets, filters]
  );

  const applyPreset = useCallback((presetFilters: FilterState) => {
    setFilters(presetFilters);
  }, []);

  return {
    filters,
    setFilters,
    sort,
    setSort,
    groupBy,
    setGroupBy,
    activeFilterCount,
    setSearch,
    setTimeMode,
    previousTimeStep,
    nextTimeStep,
    jumpToToday,
    toggleCategory,
    toggleStatus,
    togglePriority,
    setDateRange,
    setOnlyOverdue,
    clearAll,
    presets,
    savePreset,
    applyPreset,
  };
}

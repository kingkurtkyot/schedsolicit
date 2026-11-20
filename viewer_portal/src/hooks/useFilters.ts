'use client';

import { useState, useCallback, useMemo, useEffect } from 'react';
import { FilterState, GroupBy, Priority, SortState } from '@/lib/types';

const STORAGE_KEY = 'schedsolicit_filter_presets';

export function useFilters() {
  const [filters, setFilters] = useState<FilterState>({
    search: '',
    categories: [],
    statuses: [],
    priorities: [],
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

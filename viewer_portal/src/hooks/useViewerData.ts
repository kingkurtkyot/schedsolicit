'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { api } from '@/lib/api';
import { FilterState, PaginationState, SortState, StatusTab, TabModule, ViewerItem } from '@/lib/types';

interface UseViewerDataOptions {
  token: string;
  module: TabModule;
  statusTab: StatusTab;
  filters: FilterState;
  sort: SortState;
  enabled?: boolean;
}

export function useViewerData({
  token,
  module,
  statusTab,
  filters,
  sort,
  enabled = true,
}: UseViewerDataOptions) {
  const [items, setItems] = useState<ViewerItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pagination, setPagination] = useState<PaginationState>({
    page: 1,
    limit: 20,
    total: 0,
    hasMore: false,
  });

  const cacheKey = `schedsolicit_cache_${token}_${module}_${statusTab}`;
  const isInitialLoad = useRef(true);

  // Restore cached data for instant render / offline
  useEffect(() => {
    if (typeof window !== 'undefined') {
      try {
        const cached = localStorage.getItem(cacheKey);
        if (cached) {
          const parsed = JSON.parse(cached);
          if (Array.isArray(parsed) && parsed.length > 0) {
            setItems(parsed);
            setLoading(false);
          }
        }
      } catch {
        // ignore cache parse error
      }
    }
  }, [cacheKey]);

  const loadData = useCallback(
    async (pageToLoad = 1, append = false) => {
      if (!enabled || !token) return;

      if (append) {
        setLoadingMore(true);
      } else {
        setLoading(true);
      }
      setError(null);

      try {
        const params = {
          status_type: statusTab,
          page: pageToLoad,
          limit: 20,
          search: filters.search || undefined,
          category: filters.categories.length > 0 ? filters.categories : undefined,
          priority: filters.priorities.length > 0 ? filters.priorities : undefined,
          date_from: filters.dateRange?.from,
          date_to: filters.dateRange?.to,
          sort_by: sort.field,
          sort_dir: sort.direction,
        };

        let result;
        if (module === 'schedule') {
          result = await api.getSchedules(token, params);
        } else {
          result = await api.getSolicitations(token, params);
        }

        const newItems = append ? [...items, ...result.items] : result.items;
        setItems(newItems);
        setPagination({
          page: result.page,
          limit: result.limit,
          total: result.total,
          hasMore: result.hasMore,
        });

        // Cache first page
        if (pageToLoad === 1 && typeof window !== 'undefined') {
          try {
            localStorage.setItem(cacheKey, JSON.stringify(result.items));
          } catch {
            // ignore localStorage quota limit
          }
        }
      } catch (err: any) {
        setError(err.message || 'Failed to load data');
      } finally {
        setLoading(false);
        setLoadingMore(false);
        isInitialLoad.current = false;
      }
    },
    [token, module, statusTab, filters, sort, enabled, items, cacheKey]
  );

  useEffect(() => {
    loadData(1, false);
  }, [token, module, statusTab, filters.search, filters.categories, filters.priorities, filters.dateRange, sort]);

  const loadMore = useCallback(() => {
    if (!loading && !loadingMore && pagination.hasMore) {
      loadData(pagination.page + 1, true);
    }
  }, [loading, loadingMore, pagination.hasMore, pagination.page, loadData]);

  const mutateItem = useCallback((updatedItem: ViewerItem) => {
    setItems((prev) => {
      const idx = prev.findIndex((i) => i.id === updatedItem.id);
      if (idx >= 0) {
        const next = [...prev];
        next[idx] = updatedItem;
        return next;
      }
      return [updatedItem, ...prev];
    });
  }, []);

  const removeItem = useCallback((itemId: string) => {
    setItems((prev) => prev.filter((i) => i.id !== itemId));
  }, []);

  return {
    items,
    loading,
    loadingMore,
    error,
    pagination,
    loadMore,
    refetch: () => loadData(1, false),
    mutateItem,
    removeItem,
  };
}

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

  const isLocalDataset = token === 'local' || token.startsWith('SS1_');

  const loadLocalData = useCallback(() => {
    if (typeof window === 'undefined') return;
    setLoading(true);
    setError(null);

    try {
      const stored = localStorage.getItem('schedsolicit_dataset');
      if (!stored) {
        setItems([]);
        setPagination({ page: 1, limit: 20, total: 0, hasMore: false });
        setLoading(false);
        return;
      }

      const dataset = JSON.parse(stored);
      const rawList: any[] = module === 'schedule' ? (dataset.schedules || []) : (dataset.solicitations || []);

      // 1. Status Filter (Active vs History)
      let filtered = rawList.filter((item) => {
        const s = (item.status || '').toLowerCase();
        const isHistory = ['done', 'past', 'cancelled', 'given', 'declined'].includes(s);
        return statusTab === 'history' ? isHistory : !isHistory;
      });

      // 2. Search Filter
      if (filters.search && filters.search.trim()) {
        const q = filters.search.toLowerCase().trim();
        filtered = filtered.filter((item) => {
          const title = (item.title || '').toLowerCase();
          const desc = (item.description || item.purpose || '').toLowerCase();
          const loc = (item.location || item.organization || '').toLowerCase();
          return title.includes(q) || desc.includes(q) || loc.includes(q);
        });
      }

      // 3. Category Filter
      if (filters.categories && filters.categories.length > 0) {
        filtered = filtered.filter((item) => item.category && filters.categories.includes(item.category));
      }

      // 4. Priority Filter
      if (filters.priorities && filters.priorities.length > 0) {
        filtered = filtered.filter((item) => item.priority && filters.priorities.includes(item.priority));
      }

      // 5. Sort
      filtered.sort((a, b) => {
        const dateA = new Date(a.event_date || a.eventDate || a.deadline || a.created_at || 0).getTime();
        const dateB = new Date(b.event_date || b.eventDate || b.deadline || b.created_at || 0).getTime();
        return sort.direction === 'asc' ? dateA - dateB : dateB - dateA;
      });

      setItems(filtered);
      setPagination({
        page: 1,
        limit: 50,
        total: filtered.length,
        hasMore: false,
      });
    } catch (e: any) {
      setError(e.message || 'Failed to parse local dataset');
    } finally {
      setLoading(false);
    }
  }, [module, statusTab, filters, sort]);

  const loadData = useCallback(
    async (pageToLoad = 1, append = false) => {
      if (!enabled || !token) return;

      if (isLocalDataset) {
        loadLocalData();
        return;
      }

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
      } catch (err: any) {
        // If server fails or offline, attempt local storage fallback
        loadLocalData();
      } finally {
        setLoading(false);
        setLoadingMore(false);
      }
    },
    [token, module, statusTab, filters, sort, enabled, items, isLocalDataset, loadLocalData]
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

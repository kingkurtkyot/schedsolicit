'use client';

import React, { useState, useMemo, useRef, useEffect } from 'react';
import { GroupBy, ViewerItem } from '@/lib/types';
import { formatDateTime, cn } from '@/lib/utils';
import { ChevronDown, ChevronRight } from 'lucide-react';
import { SkeletonLoader } from './SkeletonLoader';

interface ListViewProps {
  items: ViewerItem[];
  groupBy: GroupBy;
  loading?: boolean;
  renderItem: (item: ViewerItem) => React.ReactNode;
  emptyMessage?: string;
}

export const ListView: React.FC<ListViewProps> = ({
  items,
  groupBy,
  loading = false,
  renderItem,
  emptyMessage = 'No items found matching the criteria.',
}) => {
  // Collapsed groups state
  const [collapsedGroups, setCollapsedGroups] = useState<Record<string, boolean>>({});

  const toggleGroup = (key: string) => {
    setCollapsedGroups((prev) => ({
      ...prev,
      [key]: !prev[key],
    }));
  };

  const groupedItems = useMemo(() => {
    if (groupBy === 'none') {
      return [{ key: 'all', title: '', items }];
    }

    const groups: Record<string, ViewerItem[]> = {};

    items.forEach((item) => {
      let groupKey = 'Other';

      if (groupBy === 'date') {
        if ('event_date' in item && item.event_date) {
          groupKey = formatDateTime(item.event_date, 'EEEE, MMM d, yyyy');
        } else if ('requested_date' in item && item.requested_date) {
          groupKey = formatDateTime(item.requested_date, 'EEEE, MMM d, yyyy');
        } else {
          groupKey = 'Undated';
        }
      } else if (groupBy === 'category') {
        groupKey = item.category || 'Uncategorized';
      } else if (groupBy === 'status') {
        groupKey = item.status || 'No Status';
      } else if (groupBy === 'priority') {
        groupKey = `${item.priority.toUpperCase()} Priority`;
      }

      if (!groups[groupKey]) {
        groups[groupKey] = [];
      }
      groups[groupKey].push(item);
    });

    return Object.entries(groups).map(([key, groupItems]) => ({
      key,
      title: key,
      items: groupItems,
    }));
  }, [items, groupBy]);

  if (loading && items.length === 0) {
    return <SkeletonLoader variant="card" count={5} />;
  }

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center p-12 text-center">
        <div className="w-16 h-16 mb-4 rounded-full bg-[var(--surface-container)] flex items-center justify-center text-[var(--color-seed)] text-2xl font-bold">
          ✓
        </div>
        <h3 className="text-base font-semibold text-[var(--text-primary)] mb-1">
          No Items Available
        </h3>
        <p className="text-xs text-[var(--text-muted)] max-w-xs">{emptyMessage}</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {groupedItems.map((group) => {
        const isCollapsed = Boolean(collapsedGroups[group.key]);

        return (
          <div key={group.key} className="space-y-2.5">
            {group.title && (
              <div
                onClick={() => toggleGroup(group.key)}
                className="sticky top-12 z-10 flex items-center justify-between py-2 px-3 rounded-lg bg-[var(--surface-bg)]/95 backdrop-blur-sm cursor-pointer hover:bg-[var(--surface-container)] transition-colors select-none"
              >
                <div className="flex items-center gap-2">
                  {isCollapsed ? (
                    <ChevronRight className="w-4 h-4 text-[var(--text-muted)]" />
                  ) : (
                    <ChevronDown className="w-4 h-4 text-[var(--text-muted)]" />
                  )}
                  <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--text-primary)]">
                    {group.title}
                  </h3>
                </div>
                <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-[var(--surface-container)] text-[var(--text-secondary)]">
                  {group.items.length}
                </span>
              </div>
            )}

            {!isCollapsed && (
              <div className="space-y-2.5">
                {group.items.map((item) => (
                  <div key={item.id}>{renderItem(item)}</div>
                ))}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
};

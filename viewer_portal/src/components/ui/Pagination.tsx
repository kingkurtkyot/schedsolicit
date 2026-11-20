'use client';

import React from 'react';
import { PaginationState } from '@/lib/types';
import { ChevronDown, Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';

interface PaginationProps {
  pagination: PaginationState;
  loadingMore: boolean;
  onLoadMore: () => void;
}

export const Pagination: React.FC<PaginationProps> = ({
  pagination,
  loadingMore,
  onLoadMore,
}) => {
  if (pagination.total <= pagination.limit && !pagination.hasMore) {
    return null;
  }

  return (
    <div className="flex flex-col items-center justify-center gap-2 py-6 px-4">
      {pagination.hasMore ? (
        <button
          type="button"
          onClick={onLoadMore}
          disabled={loadingMore}
          className={cn(
            'flex items-center justify-center gap-2 px-6 py-2.5 rounded-xl text-sm font-semibold transition-all',
            'bg-[var(--surface-container)] text-[var(--color-seed)] border border-[var(--surface-border-subtle)]',
            'hover:bg-[var(--surface-card)] active:scale-95 touch:min-h-[44px] min-w-[160px] shadow-xs'
          )}
        >
          {loadingMore ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              <span>Loading more...</span>
            </>
          ) : (
            <>
              <ChevronDown className="w-4 h-4" />
              <span>Load More</span>
            </>
          )}
        </button>
      ) : (
        <div className="text-xs text-[var(--text-muted)]">
          All items loaded ({pagination.total} total)
        </div>
      )}
      <div className="text-[11px] text-[var(--text-muted)]">
        Showing up to {pagination.page * pagination.limit} of {pagination.total} items
      </div>
    </div>
  );
};

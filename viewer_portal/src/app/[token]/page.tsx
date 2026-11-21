'use client';

import React, { useState, useMemo } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useViewerData } from '@/hooks/useViewerData';
import { useSSE } from '@/hooks/useSSE';
import { useFilters } from '@/hooks/useFilters';
import { useOffline } from '@/hooks/useOffline';
import { useResponsive } from '@/hooks/useResponsive';
import { TabModule, StatusTab, ViewMode, ViewerItem } from '@/lib/types';
import { ItemCard } from '@/components/ItemCard';
import { ItemDetail } from '@/components/ItemDetail';
import { OfflineBanner } from '@/components/OfflineBanner';
import { LastUpdated } from '@/components/LastUpdated';
import { ViewSwitcher } from '@/components/ui/ViewSwitcher';
import { TabBar } from '@/components/ui/TabBar';
import { SearchBar } from '@/components/ui/SearchBar';
import { FilterBar } from '@/components/ui/FilterBar';
import { FilterSheet } from '@/components/ui/FilterSheet';
import { ListView } from '@/components/ui/ListView';
import { Calendar } from '@/components/ui/Calendar';
import { AgendaView } from '@/components/ui/AgendaView';
import { Pagination } from '@/components/ui/Pagination';
import { SkeletonLoader } from '@/components/ui/SkeletonLoader';
import { Calendar as CalendarIcon, HandHeart, CheckCircle2, PlayCircle, SlidersHorizontal } from 'lucide-react';
import { cn } from '@/lib/utils';

export default function TokenMainPage() {
  const params = useParams();
  const router = useRouter();
  const token = typeof params.token === 'string' ? params.token : '';

  const [activeModule, setActiveModule] = useState<TabModule>('schedule');
  const [statusTab, setStatusTab] = useState<StatusTab>('active');
  const [viewMode, setViewMode] = useState<ViewMode>('list');
  const [selectedItem, setSelectedItem] = useState<ViewerItem | null>(null);
  const [isFilterSheetOpen, setIsFilterSheetOpen] = useState(false);
  const [selectedCalendarDate, setSelectedCalendarDate] = useState<Date>(new Date());

  const { isOffline } = useOffline();
  const { isDesktop, isTablet, isPhone } = useResponsive();

  const {
    filters,
    setFilters,
    sort,
    groupBy,
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
    clearAll,
  } = useFilters();

  const {
    items,
    loading,
    loadingMore,
    error,
    pagination,
    loadMore,
    refetch,
    mutateItem,
    removeItem,
  } = useViewerData({
    token,
    module: activeModule,
    statusTab,
    filters,
    sort,
  });

  // SSE connection for live updates
  const { isConnected, lastUpdatedTime, isAnimating } = useSSE({
    token,
    onUpdate: (payload) => {
      if (payload.module === activeModule) {
        if (payload.type === 'delete' && payload.itemId) {
          removeItem(payload.itemId);
        } else if (payload.data) {
          mutateItem(payload.data);
        }
      }
    },
    onPollFallback: refetch,
  });

  const handleItemSelect = (item: ViewerItem) => {
    if (isPhone) {
      router.push(`/${token}/${item.id}`);
    } else {
      setSelectedItem(item);
    }
  };

  return (
    <div className="space-y-4">
      <OfflineBanner isOffline={isOffline} />

      {/* Top Controls Bar */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 bg-[var(--surface-card)] p-3 sm:p-4 rounded-2xl border border-[var(--surface-border-subtle)] shadow-xs">
        {/* Module Switcher (Desktop / Tablet) */}
        <div className="hidden desktop:flex items-center gap-1.5 p-1 rounded-xl bg-[var(--surface-container)]">
          <button
            type="button"
            onClick={() => {
              setActiveModule('schedule');
              setSelectedItem(null);
            }}
            className={cn(
              'flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-semibold transition-all min-h-[36px]',
              activeModule === 'schedule'
                ? 'bg-[var(--surface-card)] text-[var(--color-seed)] shadow-xs'
                : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
            )}
          >
            <CalendarIcon className="w-4 h-4" />
            <span>Schedules</span>
          </button>
          <button
            type="button"
            onClick={() => {
              setActiveModule('solicitation');
              setSelectedItem(null);
            }}
            className={cn(
              'flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-semibold transition-all min-h-[36px]',
              activeModule === 'solicitation'
                ? 'bg-[var(--surface-card)] text-[var(--color-seed)] shadow-xs'
                : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
            )}
          >
            <HandHeart className="w-4 h-4" />
            <span>Solicitations</span>
          </button>
        </div>

        {/* Active | History Tabs (Desktop) */}
        <div className="hidden sm:inline-flex p-1 rounded-xl bg-[var(--surface-container)]">
          <button
            type="button"
            onClick={() => setStatusTab('active')}
            className={cn(
              'flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all min-h-[36px]',
              statusTab === 'active'
                ? 'bg-[var(--surface-card)] text-[var(--color-seed)] shadow-xs'
                : 'text-[var(--text-secondary)]'
            )}
          >
            <PlayCircle className="w-3.5 h-3.5" />
            <span>Active</span>
          </button>
          <button
            type="button"
            onClick={() => setStatusTab('history')}
            className={cn(
              'flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all min-h-[36px]',
              statusTab === 'history'
                ? 'bg-[var(--surface-card)] text-[var(--color-seed)] shadow-xs'
                : 'text-[var(--text-secondary)]'
            )}
          >
            <CheckCircle2 className="w-3.5 h-3.5" />
            <span>History</span>
          </button>
        </div>

        <div className="flex items-center justify-between sm:justify-end gap-3 w-full sm:w-auto">
          <LastUpdated lastUpdated={lastUpdatedTime} isPulsing={isAnimating} />
          <ViewSwitcher currentView={viewMode} onViewChange={setViewMode} />
        </div>
      </div>

      {/* Search & Filter Bar */}
      <div className="space-y-2">
        <SearchBar
          value={filters.search || ''}
          onChange={setSearch}
          placeholder={`Search ${activeModule === 'schedule' ? 'schedules' : 'solicitations'}...`}
        />
        <FilterBar
          filters={filters}
          activeCount={activeFilterCount}
          totalResults={pagination.total}
          onOpenFilterSheet={() => setIsFilterSheetOpen(true)}
          onSetTimeMode={setTimeMode}
          onPreviousStep={previousTimeStep}
          onNextStep={nextTimeStep}
          onJumpToToday={jumpToToday}
          onRemoveCategory={toggleCategory}
          onRemoveStatus={toggleStatus}
          onRemovePriority={togglePriority}
          onClearDateRange={() => setDateRange(undefined, undefined)}
          onClearAll={clearAll}
        />
      </div>

      {/* Filter Sheet Side / Bottom Modal */}
      <FilterSheet
        isOpen={isFilterSheetOpen}
        onClose={() => setIsFilterSheetOpen(false)}
        filters={filters}
        onApplyFilters={setFilters}
      />

      {/* Main Responsive Grid Layout */}
      <div
        className={cn(
          'grid gap-6',
          // Desktop: 3-pane or 2-pane (list + detail)
          isDesktop && selectedItem ? 'grid-cols-12' : 'grid-cols-1',
          isTablet && selectedItem ? 'grid-cols-12' : 'grid-cols-1'
        )}
      >
        {/* Left / Main Items Column */}
        <div
          className={cn(
            'space-y-4',
            (isDesktop || isTablet) && selectedItem ? 'col-span-6 xl:col-span-5' : 'col-span-12'
          )}
        >
          {loading && items.length === 0 ? (
            <SkeletonLoader variant="card" count={4} />
          ) : viewMode === 'calendar' ? (
            <Calendar
              items={items}
              selectedDate={selectedCalendarDate}
              onSelectDate={setSelectedCalendarDate}
              onSelectItem={handleItemSelect}
            />
          ) : viewMode === 'agenda' ? (
            <AgendaView
              items={items}
              renderItem={(item) => (
                <ItemCard
                  key={item.id}
                  item={item}
                  onClick={() => handleItemSelect(item)}
                />
              )}
            />
          ) : (
            <ListView
              items={items}
              groupBy={groupBy}
              loading={loading}
              renderItem={(item) => (
                <ItemCard
                  key={item.id}
                  item={item}
                  onClick={() => handleItemSelect(item)}
                />
              )}
            />
          )}

          {/* Pagination */}
          <Pagination
            pagination={pagination}
            loadingMore={loadingMore}
            onLoadMore={loadMore}
          />
        </div>

        {/* Right / Detail Column (for Tablet / Desktop) */}
        {(isDesktop || isTablet) && selectedItem && (
          <div className="col-span-6 xl:col-span-7 sticky top-20 self-start">
            <ItemDetail
              item={selectedItem}
              onBack={() => setSelectedItem(null)}
            />
          </div>
        )}
      </div>

      {/* Mobile Tab Bar */}
      <TabBar
        activeModule={activeModule}
        onModuleChange={(mod) => {
          setActiveModule(mod);
          setSelectedItem(null);
        }}
        statusTab={statusTab}
        onStatusChange={setStatusTab}
      />
    </div>
  );
}

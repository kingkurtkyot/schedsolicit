'use client';

import React, { useState, useMemo, useRef } from 'react';
import {
  format,
  addMonths,
  subMonths,
  startOfWeek,
  endOfWeek,
  startOfMonth,
  endOfMonth,
  eachDayOfInterval,
  isSameMonth,
  isSameDay,
  isToday,
  parseISO,
} from 'date-fns';
import { ViewerItem, ScheduleItem, SolicitationItem } from '@/lib/types';
import { ChevronLeft, ChevronRight, Calendar as CalIcon } from 'lucide-react';
import { cn, formatDateTime } from '@/lib/utils';

interface CalendarProps {
  items: ViewerItem[];
  selectedDate?: Date;
  onSelectDate: (date: Date) => void;
  onSelectItem?: (item: ViewerItem) => void;
  mini?: boolean;
}

export const Calendar: React.FC<CalendarProps> = ({
  items,
  selectedDate = new Date(),
  onSelectDate,
  onSelectItem,
  mini = false,
}) => {
  const [currentMonth, setCurrentMonth] = useState(selectedDate);
  const touchStartX = useRef<number | null>(null);

  // Map items to date string keys (YYYY-MM-DD)
  const itemsByDate = useMemo(() => {
    const map = new Map<string, ViewerItem[]>();
    items.forEach((item) => {
      let dateStr = '';
      if ('event_date' in item && item.event_date) {
        dateStr = item.event_date.split('T')[0];
      } else if ('requested_date' in item && item.requested_date) {
        dateStr = item.requested_date.split('T')[0];
      } else if ('deadline' in item && item.deadline) {
        dateStr = item.deadline.split('T')[0];
      }

      if (dateStr) {
        const list = map.get(dateStr) || [];
        list.push(item);
        map.set(dateStr, list);
      }
    });
    return map;
  }, [items]);

  const monthStart = startOfMonth(currentMonth);
  const monthEnd = endOfMonth(monthStart);
  const startDate = startOfWeek(monthStart, { weekStartsOn: 0 });
  const endDate = endOfWeek(monthEnd, { weekStartsOn: 0 });

  const days = useMemo(() => {
    return eachDayOfInterval({ start: startDate, end: endDate });
  }, [startDate, endDate]);

  const prevMonth = () => setCurrentMonth(subMonths(currentMonth, 1));
  const nextMonth = () => setCurrentMonth(addMonths(currentMonth, 1));

  // Swipe support for touch devices (iOS Safari)
  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartX.current = e.touches[0].clientX;
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    if (touchStartX.current === null) return;
    const diff = e.changedTouches[0].clientX - touchStartX.current;
    if (diff > 50) {
      prevMonth();
    } else if (diff < -50) {
      nextMonth();
    }
    touchStartX.current = null;
  };

  const selectedDateKey = format(selectedDate, 'yyyy-MM-dd');
  const selectedDayItems = itemsByDate.get(selectedDateKey) || [];

  return (
    <div
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
      className={cn(
        'rounded-2xl border border-[var(--surface-border-subtle)] bg-[var(--surface-card)] overflow-hidden shadow-xs',
        mini ? 'p-3' : 'p-4 sm:p-6'
      )}
    >
      {/* Calendar Header */}
      <div className="flex items-center justify-between pb-4">
        <h2 className={cn('font-bold text-[var(--text-primary)]', mini ? 'text-sm' : 'text-base sm:text-lg')}>
          {format(currentMonth, 'MMMM yyyy')}
        </h2>
        <div className="flex items-center gap-1">
          <button
            type="button"
            onClick={prevMonth}
            aria-label="Previous month"
            className="p-2 rounded-lg text-[var(--text-secondary)] hover:bg-[var(--surface-container)] active:scale-95 touch:min-h-[44px] touch:min-w-[44px] flex items-center justify-center"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <button
            type="button"
            onClick={() => {
              const today = new Date();
              setCurrentMonth(today);
              onSelectDate(today);
            }}
            className="px-2.5 py-1 text-xs font-semibold rounded-lg text-[var(--color-seed)] hover:bg-[var(--surface-container)]"
          >
            Today
          </button>
          <button
            type="button"
            onClick={nextMonth}
            aria-label="Next month"
            className="p-2 rounded-lg text-[var(--text-secondary)] hover:bg-[var(--surface-container)] active:scale-95 touch:min-h-[44px] touch:min-w-[44px] flex items-center justify-center"
          >
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Weekday Labels */}
      <div className="grid grid-cols-7 mb-2 text-center">
        {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d, i) => (
          <div key={i} className="text-[11px] font-semibold text-[var(--text-muted)] py-1">
            {mini ? d[0] : d}
          </div>
        ))}
      </div>

      {/* Calendar Grid */}
      <div className="grid grid-cols-7 gap-1">
        {days.map((day, idx) => {
          const dateKey = format(day, 'yyyy-MM-dd');
          const dayItems = itemsByDate.get(dateKey) || [];
          const isSelected = isSameDay(day, selectedDate);
          const isCurrentM = isSameMonth(day, currentMonth);
          const isDayToday = isToday(day);

          return (
            <button
              key={idx}
              type="button"
              onClick={() => onSelectDate(day)}
              className={cn(
                'relative flex flex-col items-center justify-between rounded-xl transition-all duration-150',
                mini ? 'h-10 p-0.5' : 'h-14 sm:h-20 p-1.5',
                isCurrentM ? 'text-[var(--text-primary)]' : 'text-[var(--text-muted)] opacity-40',
                isSelected
                  ? 'bg-[var(--color-seed)]/15 border-2 border-[var(--color-seed)] font-bold'
                  : 'hover:bg-[var(--surface-container)] border border-transparent',
                'touch:min-h-[44px]'
              )}
            >
              <span
                className={cn(
                  'flex items-center justify-center w-6 h-6 text-xs rounded-full',
                  isDayToday && 'bg-[var(--color-seed)] text-white font-bold'
                )}
              >
                {format(day, 'd')}
              </span>

              {/* Indicator dots for items */}
              {dayItems.length > 0 && (
                <div className="flex items-center gap-0.5 mt-auto overflow-hidden">
                  {dayItems.slice(0, 3).map((item, i) => (
                    <span
                      key={i}
                      className="w-1.5 h-1.5 rounded-full bg-[var(--color-seed)]"
                    />
                  ))}
                  {dayItems.length > 3 && !mini && (
                    <span className="text-[9px] font-bold text-[var(--color-seed)] leading-none">
                      +{dayItems.length - 3}
                    </span>
                  )}
                </div>
              )}
            </button>
          );
        })}
      </div>

      {/* Selected Day Agenda Drawer / Summary */}
      {!mini && (
        <div className="mt-5 pt-4 border-t border-[var(--surface-border-subtle)]">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)]">
              {format(selectedDate, 'EEEE, MMMM d, yyyy')}
            </h3>
            <span className="text-xs font-semibold text-[var(--color-seed)]">
              {selectedDayItems.length} {selectedDayItems.length === 1 ? 'item' : 'items'}
            </span>
          </div>

          {selectedDayItems.length === 0 ? (
            <p className="text-xs text-[var(--text-muted)] py-3 text-center">
              No items scheduled for this day.
            </p>
          ) : (
            <div className="space-y-2 max-h-56 overflow-y-auto pr-1">
              {selectedDayItems.map((item) => (
                <div
                  key={item.id}
                  onClick={() => onSelectItem?.(item)}
                  className="flex items-center justify-between p-2.5 rounded-xl bg-[var(--surface-container)] hover:bg-[var(--surface-card-subtle)] cursor-pointer border border-[var(--surface-border-subtle)] transition-all"
                >
                  <div className="truncate pr-2">
                    <p className="text-sm font-semibold text-[var(--text-primary)] truncate">
                      {item.title}
                    </p>
                    <p className="text-xs text-[var(--text-muted)]">
                      {formatDateTime(item.created_at)}
                    </p>
                  </div>
                  <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-[var(--surface-card)] border border-[var(--surface-border)]">
                    {item.priority}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

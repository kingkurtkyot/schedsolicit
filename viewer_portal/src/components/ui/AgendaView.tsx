'use client';

import React, { useMemo } from 'react';
import { ViewerItem, ScheduleItem, SolicitationItem } from '@/lib/types';
import { formatTime, cn } from '@/lib/utils';
import { Clock, Calendar as CalIcon } from 'lucide-react';

interface AgendaViewProps {
  items: ViewerItem[];
  renderItem: (item: ViewerItem) => React.ReactNode;
}

export const AgendaView: React.FC<AgendaViewProps> = ({ items, renderItem }) => {
  // Separate into all-day vs timed items
  const { allDayItems, timedItems } = useMemo(() => {
    const allDay: ViewerItem[] = [];
    const timed: ViewerItem[] = [];

    items.forEach((item) => {
      if ('all_day' in item && item.all_day) {
        allDay.push(item);
      } else if ('start_time' in item && item.start_time) {
        timed.push(item);
      } else {
        allDay.push(item);
      }
    });

    // Sort timed items by start time
    timed.sort((a, b) => {
      const timeA = (a as ScheduleItem).start_time || '00:00';
      const timeB = (b as ScheduleItem).start_time || '00:00';
      return timeA.localeCompare(timeB);
    });

    return { allDayItems: allDay, timedItems: timed };
  }, [items]);

  return (
    <div className="space-y-6">
      {/* All-Day Section */}
      {allDayItems.length > 0 && (
        <div className="p-4 rounded-2xl bg-[var(--surface-container)] border border-[var(--surface-border-subtle)] space-y-3">
          <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-[var(--color-seed)]">
            <CalIcon className="w-4 h-4" />
            <span>All-Day / Untimed Items</span>
            <span className="ml-auto px-2 py-0.5 rounded-full bg-[var(--surface-card)] text-xs">
              {allDayItems.length}
            </span>
          </div>
          <div className="space-y-2">
            {allDayItems.map((item) => (
              <div key={item.id}>{renderItem(item)}</div>
            ))}
          </div>
        </div>
      )}

      {/* Timed Timeline */}
      <div className="relative pl-6 sm:pl-8 space-y-6 before:absolute before:left-2 sm:before:left-3 before:top-2 before:bottom-2 before:w-0.5 before:bg-[var(--surface-border)]">
        {timedItems.map((item) => {
          const sched = item as ScheduleItem;
          const timeLabel = formatTime(sched.start_time);

          return (
            <div key={item.id} className="relative space-y-1">
              {/* Timeline Dot Marker */}
              <div className="absolute -left-6 sm:-left-8 top-3 w-4 h-4 rounded-full bg-[var(--surface-card)] border-2 border-[var(--color-seed)] flex items-center justify-center">
                <span className="w-1.5 h-1.5 rounded-full bg-[var(--color-seed)]" />
              </div>

              {/* Time header */}
              <div className="flex items-center gap-1.5 text-xs font-semibold text-[var(--color-seed)] pb-1">
                <Clock className="w-3.5 h-3.5" />
                <span>
                  {timeLabel}
                  {sched.end_time ? ` - ${formatTime(sched.end_time)}` : ''}
                </span>
              </div>

              {/* Item Card */}
              {renderItem(item)}
            </div>
          );
        })}
      </div>
    </div>
  );
};

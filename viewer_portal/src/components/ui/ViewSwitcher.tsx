'use client';

import React from 'react';
import { ViewMode } from '@/lib/types';
import { List, Calendar as CalendarIcon, Clock } from 'lucide-react';
import { cn } from '@/lib/utils';

interface ViewSwitcherProps {
  currentView: ViewMode;
  onViewChange: (view: ViewMode) => void;
}

export const ViewSwitcher: React.FC<ViewSwitcherProps> = ({ currentView, onViewChange }) => {
  const views: { id: ViewMode; label: string; icon: React.ReactNode }[] = [
    { id: 'list', label: 'List', icon: <List className="w-4 h-4" /> },
    { id: 'calendar', label: 'Calendar', icon: <CalendarIcon className="w-4 h-4" /> },
    { id: 'agenda', label: 'Agenda', icon: <Clock className="w-4 h-4" /> },
  ];

  return (
    <div
      role="group"
      aria-label="View switcher"
      className="inline-flex p-1 rounded-xl bg-[var(--surface-container)] border border-[var(--surface-border-subtle)]"
    >
      {views.map((v) => {
        const isActive = currentView === v.id;
        return (
          <button
            key={v.id}
            type="button"
            onClick={() => onViewChange(v.id)}
            aria-pressed={isActive}
            className={cn(
              'flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all duration-150',
              'min-h-[36px] touch:min-h-[44px] touch:px-3.5',
              isActive
                ? 'bg-[var(--surface-card)] text-[var(--color-seed)] shadow-xs font-semibold'
                : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
            )}
          >
            {v.icon}
            <span>{v.label}</span>
          </button>
        );
      })}
    </div>
  );
};

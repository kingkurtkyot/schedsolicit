'use client';

import React from 'react';
import { StatusTab, TabModule } from '@/lib/types';
import { Calendar, HandHeart, CheckCircle2, PlayCircle } from 'lucide-react';
import { cn } from '@/lib/utils';

interface TabBarProps {
  activeModule: TabModule;
  onModuleChange: (mod: TabModule) => void;
  statusTab: StatusTab;
  onStatusChange: (status: StatusTab) => void;
  allowedModules?: TabModule[];
}

export const TabBar: React.FC<TabBarProps> = ({
  activeModule,
  onModuleChange,
  statusTab,
  onStatusChange,
  allowedModules = ['schedule', 'solicitation'],
}) => {
  const showBothModules = allowedModules.includes('schedule') && allowedModules.includes('solicitation');

  return (
    <nav
      aria-label="Navigation tabs"
      className="fixed bottom-0 left-0 right-0 z-40 bg-[var(--surface-card)] border-t border-[var(--surface-border-subtle)] pb-[env(safe-area-inset-bottom,0px)] shadow-lg desktop:hidden"
    >
      <div className="flex flex-col">
        {/* Active | History segmented control */}
        <div className="flex justify-center px-4 pt-2 pb-1 border-b border-[var(--surface-border-subtle)]">
          <div className="inline-flex w-full max-w-xs p-0.5 rounded-lg bg-[var(--surface-container)]">
            <button
              type="button"
              onClick={() => onStatusChange('active')}
              className={cn(
                'flex-1 flex items-center justify-center gap-1.5 py-1.5 rounded-md text-xs font-semibold transition-all min-h-[36px]',
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
              onClick={() => onStatusChange('history')}
              className={cn(
                'flex-1 flex items-center justify-center gap-1.5 py-1.5 rounded-md text-xs font-semibold transition-all min-h-[36px]',
                statusTab === 'history'
                  ? 'bg-[var(--surface-card)] text-[var(--color-seed)] shadow-xs'
                  : 'text-[var(--text-secondary)]'
              )}
            >
              <CheckCircle2 className="w-3.5 h-3.5" />
              <span>History</span>
            </button>
          </div>
        </div>

        {/* Schedule vs Solicitations tabs (if both allowed) */}
        {showBothModules && (
          <div className="grid grid-cols-2 h-14">
            <button
              type="button"
              onClick={() => onModuleChange('schedule')}
              className={cn(
                'flex flex-col items-center justify-center gap-1 text-xs font-medium transition-colors min-h-[44px]',
                activeModule === 'schedule'
                  ? 'text-[var(--color-seed)] font-semibold'
                  : 'text-[var(--text-muted)]'
              )}
            >
              <Calendar className="w-5 h-5" />
              <span>Schedule</span>
            </button>
            <button
              type="button"
              onClick={() => onModuleChange('solicitation')}
              className={cn(
                'flex flex-col items-center justify-center gap-1 text-xs font-medium transition-colors min-h-[44px]',
                activeModule === 'solicitation'
                  ? 'text-[var(--color-seed)] font-semibold'
                  : 'text-[var(--text-muted)]'
              )}
            >
              <HandHeart className="w-5 h-5" />
              <span>Solicitations</span>
            </button>
          </div>
        )}
      </div>
    </nav>
  );
};

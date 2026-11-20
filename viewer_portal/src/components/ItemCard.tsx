'use client';

import React from 'react';
import { ViewerItem, ScheduleItem, SolicitationItem, PrivacyControls } from '@/lib/types';
import { Card } from './ui/Card';
import { Chip } from './ui/Chip';
import {
  formatCompactDateLine,
  formatCurrency,
  getStatusColor,
  getPriorityColor,
  isItemOverdue,
  cn,
} from '@/lib/utils';
import {
  Clock,
  MapPin,
  Building2,
  AlertTriangle,
  ArrowUpRight,
  Paperclip,
} from 'lucide-react';

interface ItemCardProps {
  item: ViewerItem;
  privacyControls?: PrivacyControls;
  onClick?: () => void;
  className?: string;
}

export const ItemCard: React.FC<ItemCardProps> = ({
  item,
  privacyControls = {},
  onClick,
  className,
}) => {
  const isSchedule = 'event_date' in item;
  const isSolicitation = !isSchedule;

  const sched = isSchedule ? (item as ScheduleItem) : null;
  const solic = isSolicitation ? (item as SolicitationItem) : null;

  const overdue = isItemOverdue(item);
  const statusColor = getStatusColor(item.status);
  const priorityColor = getPriorityColor(item.priority);
  const dateLine = formatCompactDateLine(item);

  // Field stripping / privacy control checks
  const showContact = !privacyControls.hide_contact_info;
  const showAmounts = !privacyControls.mask_amounts;

  return (
    <Card
      interactive
      onClick={onClick}
      className={cn(
        'group flex flex-col justify-between border-l-4 transition-all duration-200',
        overdue ? 'border-l-red-500' : 'border-l-[var(--color-seed)]',
        className
      )}
    >
      <div className="space-y-2.5">
        {/* Top Header: Category/Type + Status + Priority */}
        <div className="flex items-center justify-between gap-2 flex-wrap">
          <div className="flex items-center gap-1.5 flex-wrap">
            {item.category && (
              <Chip
                label={item.category}
                className="text-[10px] py-0.5 px-2 bg-[var(--surface-container)] text-[var(--text-secondary)] border-transparent"
              />
            )}
            <Chip
              label={item.status}
              color={statusColor}
              className="text-[10px] py-0.5 px-2 font-semibold"
            />
            {overdue && (
              <span className="inline-flex items-center gap-1 text-[10px] font-bold text-red-600 dark:text-red-400 bg-red-100 dark:bg-red-950/80 px-2 py-0.5 rounded-full border border-red-300 dark:border-red-900">
                <AlertTriangle className="w-3 h-3" />
                <span>Overdue</span>
              </span>
            )}
          </div>

          {/* Priority indicator */}
          <div className="flex items-center gap-1 text-xs font-semibold capitalize" style={{ color: priorityColor }}>
            <span
              className="w-2 h-2 rounded-full"
              style={{ backgroundColor: priorityColor }}
            />
            <span className="text-[11px]">{item.priority}</span>
          </div>
        </div>

        {/* Title */}
        <h3 className="text-base font-bold text-[var(--text-primary)] group-hover:text-[var(--color-seed)] transition-colors leading-snug">
          {item.title}
        </h3>

        {/* Compact Date Line */}
        <div className="flex items-center gap-1.5 text-xs font-medium text-[var(--text-secondary)]">
          <Clock className="w-3.5 h-3.5 text-[var(--color-seed)] flex-shrink-0" />
          <span className="truncate">{dateLine}</span>
        </div>

        {/* Location or Organization / Contact info */}
        <div className="flex items-center gap-3 text-xs text-[var(--text-muted)] flex-wrap">
          {item.location && (
            <div className="flex items-center gap-1 truncate max-w-[200px]">
              <MapPin className="w-3 h-3 flex-shrink-0" />
              <span className="truncate">{item.location}</span>
            </div>
          )}

          {solic?.organization && showContact && (
            <div className="flex items-center gap-1 truncate max-w-[200px]">
              <Building2 className="w-3 h-3 flex-shrink-0" />
              <span className="truncate">{solic.organization}</span>
            </div>
          )}
        </div>
      </div>

      {/* Card Footer: Requested / Given amount or Attachment count */}
      <div className="mt-3.5 pt-2.5 border-t border-[var(--surface-border-subtle)] flex items-center justify-between">
        <div>
          {solic?.amount_requested != null && (
            <div className="text-sm font-extrabold text-[var(--text-primary)]">
              {formatCurrency(solic.amount_requested, !showAmounts)}
              <span className="text-[11px] font-normal text-[var(--text-muted)] ml-1">
                requested
              </span>
            </div>
          )}
          {solic?.given_amount != null && (
            <div className="text-sm font-extrabold text-[var(--color-seed)]">
              {formatCurrency(solic.given_amount, !showAmounts)}
              <span className="text-[11px] font-normal text-[var(--text-muted)] ml-1">
                given
              </span>
            </div>
          )}
          {isSchedule && sched?.description && (
            <p className="text-xs text-[var(--text-muted)] line-clamp-1 max-w-sm">
              {sched.description}
            </p>
          )}
        </div>

        <div className="flex items-center gap-2">
          {item.attachments && item.attachments.length > 0 && (
            <span className="inline-flex items-center gap-1 text-[11px] text-[var(--text-muted)]">
              <Paperclip className="w-3 h-3" />
              <span>{item.attachments.length}</span>
            </span>
          )}
          <ArrowUpRight className="w-4 h-4 text-[var(--text-muted)] group-hover:text-[var(--color-seed)] transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
        </div>
      </div>
    </Card>
  );
};

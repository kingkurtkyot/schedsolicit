'use client';

import React, { useState } from 'react';
import { ViewerItem, ScheduleItem, SolicitationItem, PrivacyControls } from '@/lib/types';
import { Card } from './ui/Card';
import { Chip } from './ui/Chip';
import {
  formatDateTime,
  formatTime,
  formatCurrency,
  getStatusColor,
  getPriorityColor,
  cn,
} from '@/lib/utils';
import {
  ArrowLeft,
  Calendar,
  Clock,
  MapPin,
  Building2,
  Mail,
  Phone,
  FileText,
  Paperclip,
  History,
  Info,
  DollarSign,
  Gift,
} from 'lucide-react';

interface ItemDetailProps {
  item: ViewerItem;
  privacyControls?: PrivacyControls;
  onBack: () => void;
}

export const ItemDetail: React.FC<ItemDetailProps> = ({
  item,
  privacyControls = {},
  onBack,
}) => {
  const [activeTab, setActiveTab] = useState<'details' | 'timeline' | 'attachments'>('details');

  const isSchedule = 'event_date' in item;
  const isSolicitation = !isSchedule;

  const sched = isSchedule ? (item as ScheduleItem) : null;
  const solic = isSolicitation ? (item as SolicitationItem) : null;

  const statusColor = getStatusColor(item.status);
  const priorityColor = getPriorityColor(item.priority);

  // Field stripping checks
  const showContact = !privacyControls.hide_contact_info;
  const showAmounts = !privacyControls.mask_amounts;
  const showNotes = !privacyControls.hide_internal_notes;
  const showAudit = !privacyControls.hide_audit_trail;
  const showAttachments = !privacyControls.strip_attachments;

  return (
    <div className="space-y-6 max-w-4xl mx-auto pb-12">
      {/* Back button and navigation */}
      <div className="flex items-center justify-between">
        <button
          type="button"
          onClick={onBack}
          className="inline-flex items-center gap-1.5 text-xs font-semibold text-[var(--color-seed)] hover:underline active:scale-95 touch:min-h-[44px]"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back to list</span>
        </button>

        <div className="flex items-center gap-2">
          {item.category && (
            <Chip
              label={item.category}
              className="bg-[var(--surface-container)] text-[var(--text-secondary)] border-transparent"
            />
          )}
          <Chip label={item.status} color={statusColor} className="font-semibold" />
        </div>
      </div>

      {/* Main Header Card */}
      <Card mode="expanded" className="space-y-4">
        <div className="space-y-2">
          <div className="flex items-center gap-2">
            <span
              className="w-2.5 h-2.5 rounded-full"
              style={{ backgroundColor: priorityColor }}
            />
            <span
              className="text-xs font-bold uppercase tracking-wider"
              style={{ color: priorityColor }}
            >
              {item.priority} Priority
            </span>
          </div>

          <h1 className="text-xl sm:text-2xl font-extrabold text-[var(--text-primary)] leading-tight">
            {item.title}
          </h1>
        </div>

        {/* Date context banner */}
        <div className="p-3.5 rounded-xl bg-[var(--surface-container)] border border-[var(--surface-border-subtle)] space-y-1.5">
          <div className="flex items-center gap-2 text-xs font-semibold text-[var(--text-primary)]">
            <Calendar className="w-4 h-4 text-[var(--color-seed)]" />
            {isSchedule && sched && (
              <span>
                {formatDateTime(sched.event_date, 'EEEE, MMMM d, yyyy')}
                {sched.all_day
                  ? ' · All Day'
                  : sched.start_time
                  ? ` · ${formatTime(sched.start_time)}${sched.end_time ? ` - ${formatTime(sched.end_time)}` : ''}`
                  : ''}
              </span>
            )}
            {isSolicitation && solic && (
              <span>
                {solic.requested_date ? `Made ${formatDateTime(solic.requested_date)}` : ''}
                {solic.deadline ? ` · Due ${formatDateTime(solic.deadline)}` : ''}
                {solic.given_date ? ` · Given ${formatDateTime(solic.given_date)}` : ''}
              </span>
            )}
          </div>
        </div>

        {/* Tabs for Details, Timeline, Attachments */}
        <div className="flex items-center gap-2 border-b border-[var(--surface-border-subtle)] pt-2">
          <button
            type="button"
            onClick={() => setActiveTab('details')}
            className={cn(
              'px-4 py-2.5 text-xs font-bold border-b-2 transition-all min-h-[44px]',
              activeTab === 'details'
                ? 'border-[var(--color-seed)] text-[var(--color-seed)]'
                : 'border-transparent text-[var(--text-muted)] hover:text-[var(--text-primary)]'
            )}
          >
            Details
          </button>
          {showAudit && (
            <button
              type="button"
              onClick={() => setActiveTab('timeline')}
              className={cn(
                'px-4 py-2.5 text-xs font-bold border-b-2 transition-all min-h-[44px]',
                activeTab === 'timeline'
                  ? 'border-[var(--color-seed)] text-[var(--color-seed)]'
                  : 'border-transparent text-[var(--text-muted)] hover:text-[var(--text-primary)]'
              )}
            >
              Timeline & Audit
            </button>
          )}
          {showAttachments && item.attachments && item.attachments.length > 0 && (
            <button
              type="button"
              onClick={() => setActiveTab('attachments')}
              className={cn(
                'px-4 py-2.5 text-xs font-bold border-b-2 transition-all min-h-[44px]',
                activeTab === 'attachments'
                  ? 'border-[var(--color-seed)] text-[var(--color-seed)]'
                  : 'border-transparent text-[var(--text-muted)] hover:text-[var(--text-primary)]'
              )}
            >
              Attachments ({item.attachments.length})
            </button>
          )}
        </div>

        {/* Tab Content */}
        {activeTab === 'details' && (
          <div className="space-y-6 pt-2">
            {/* Description or Purpose */}
            {isSchedule && sched?.description && (
              <div className="space-y-1.5">
                <h4 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)]">
                  Description
                </h4>
                <p className="text-sm text-[var(--text-primary)] whitespace-pre-line leading-relaxed">
                  {sched.description}
                </p>
              </div>
            )}

            {isSolicitation && solic?.purpose && (
              <div className="space-y-1.5">
                <h4 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)]">
                  Purpose
                </h4>
                <p className="text-sm text-[var(--text-primary)] whitespace-pre-line leading-relaxed">
                  {solic.purpose}
                </p>
              </div>
            )}

            {/* Requested vs Given section for Solicitations */}
            {isSolicitation && solic && (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="p-4 rounded-xl bg-[var(--surface-container)] border border-[var(--surface-border-subtle)] space-y-2">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-[var(--text-muted)]">
                    <DollarSign className="w-4 h-4 text-[var(--color-seed)]" />
                    <span>REQUESTED</span>
                  </div>
                  <div className="text-lg font-black text-[var(--text-primary)]">
                    {formatCurrency(solic.amount_requested, !showAmounts) || 'N/A'}
                  </div>
                  {solic.quantity_requested && (
                    <div className="text-xs text-[var(--text-secondary)]">
                      Qty: {solic.quantity_requested}
                    </div>
                  )}
                </div>

                <div className="p-4 rounded-xl bg-[var(--surface-container)] border border-[var(--surface-border-subtle)] space-y-2">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-[var(--color-seed)]">
                    <Gift className="w-4 h-4 text-[var(--color-seed)]" />
                    <span>FULFILLMENT / GIVEN</span>
                  </div>
                  <div className="text-lg font-black text-[var(--color-seed)]">
                    {formatCurrency(solic.given_amount, !showAmounts) || 'None recorded'}
                  </div>
                  {solic.given_item && (
                    <div className="text-xs text-[var(--text-secondary)]">
                      Item: {solic.given_item}
                    </div>
                  )}
                  {solic.given_by && (
                    <div className="text-xs text-[var(--text-muted)]">
                      By: {solic.given_by}
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Organization & Contact section */}
            {showContact && (item.location || solic?.organization || solic?.contact_person) && (
              <div className="space-y-3 pt-2">
                <h4 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)]">
                  Location & Contact
                </h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
                  {item.location && (
                    <div className="flex items-center gap-2 text-[var(--text-secondary)]">
                      <MapPin className="w-4 h-4 text-[var(--color-seed)] flex-shrink-0" />
                      <span>{item.location}</span>
                    </div>
                  )}
                  {solic?.organization && (
                    <div className="flex items-center gap-2 text-[var(--text-secondary)]">
                      <Building2 className="w-4 h-4 text-[var(--color-seed)] flex-shrink-0" />
                      <span>{solic.organization}</span>
                    </div>
                  )}
                  {solic?.contact_person && (
                    <div className="flex items-center gap-2 text-[var(--text-secondary)]">
                      <Info className="w-4 h-4 text-[var(--color-seed)] flex-shrink-0" />
                      <span>{solic.contact_person}</span>
                    </div>
                  )}
                  {solic?.email && (
                    <div className="flex items-center gap-2 text-[var(--text-secondary)]">
                      <Mail className="w-4 h-4 text-[var(--color-seed)] flex-shrink-0" />
                      <a href={`mailto:${solic.email}`} className="text-[var(--color-seed)] underline">
                        {solic.email}
                      </a>
                    </div>
                  )}
                  {solic?.phone && (
                    <div className="flex items-center gap-2 text-[var(--text-secondary)]">
                      <Phone className="w-4 h-4 text-[var(--color-seed)] flex-shrink-0" />
                      <a href={`tel:${solic.phone}`} className="text-[var(--color-seed)] underline">
                        {solic.phone}
                      </a>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Internal Notes */}
            {showNotes && item.notes && (
              <div className="space-y-1.5 pt-2">
                <h4 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)]">
                  Notes
                </h4>
                <p className="text-xs text-[var(--text-secondary)] bg-[var(--surface-container)] p-3 rounded-xl whitespace-pre-line">
                  {item.notes}
                </p>
              </div>
            )}
          </div>
        )}

        {/* Timeline Tab */}
        {activeTab === 'timeline' && showAudit && (
          <div className="space-y-4 pt-2">
            {item.audit_logs && item.audit_logs.length > 0 ? (
              <div className="relative pl-6 space-y-4 before:absolute before:left-2 before:top-2 before:bottom-2 before:w-0.5 before:bg-[var(--surface-border)]">
                {item.audit_logs.map((log) => (
                  <div key={log.id} className="relative space-y-1">
                    <span className="absolute -left-6 top-1.5 w-3 h-3 rounded-full bg-[var(--color-seed)] border-2 border-[var(--surface-card)]" />
                    <div className="flex items-center justify-between text-xs">
                      <span className="font-bold text-[var(--text-primary)] capitalize">
                        {log.action} {log.field ? `(${log.field})` : ''}
                      </span>
                      <span className="text-[var(--text-muted)]">
                        {formatDateTime(log.timestamp, 'MMM d, h:mm a')}
                      </span>
                    </div>
                    {log.old_value && log.new_value && (
                      <p className="text-xs text-[var(--text-secondary)]">
                        Changed from <span className="line-through">{log.old_value}</span> to{' '}
                        <span className="font-semibold text-[var(--color-seed)]">{log.new_value}</span>
                      </p>
                    )}
                    <p className="text-[11px] text-[var(--text-muted)]">By: {log.actor}</p>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs text-[var(--text-muted)] py-4 text-center">
                No audit entries recorded for this item.
              </p>
            )}
          </div>
        )}

        {/* Attachments Tab */}
        {activeTab === 'attachments' && showAttachments && (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
            {item.attachments?.map((att) => (
              <div
                key={att.id}
                className="flex items-center justify-between p-3 rounded-xl bg-[var(--surface-container)] border border-[var(--surface-border-subtle)]"
              >
                <div className="flex items-center gap-2 truncate pr-2">
                  <FileText className="w-4 h-4 text-[var(--color-seed)] flex-shrink-0" />
                  <span className="text-xs font-semibold text-[var(--text-primary)] truncate">
                    {att.file_name || 'Attachment'}
                  </span>
                </div>
                {att.url && (
                  <a
                    href={att.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-xs font-bold text-[var(--color-seed)] hover:underline flex-shrink-0 px-2 py-1"
                  >
                    View
                  </a>
                )}
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  );
};

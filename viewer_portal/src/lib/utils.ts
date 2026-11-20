import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { format, formatDistanceToNow, parseISO, isAfter, isBefore, isValid } from 'date-fns';
import { Priority, ScheduleItem, SolicitationItem, ViewerItem } from './types';
import { TOKENS } from './tokens';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDateTime(dateStr?: string | null, formatPattern: string = 'MMM d, yyyy'): string {
  if (!dateStr) return '';
  try {
    const d = parseISO(dateStr);
    if (!isValid(d)) return dateStr;
    return format(d, formatPattern);
  } catch {
    return dateStr || '';
  }
}

export function formatTime(timeStr?: string | null): string {
  if (!timeStr) return '';
  try {
    const parts = timeStr.split(':');
    if (parts.length >= 2) {
      const hours = parseInt(parts[0], 10);
      const minutes = parseInt(parts[1], 10);
      const period = hours >= 12 ? 'PM' : 'AM';
      const h12 = hours % 12 || 12;
      return `${h12}:${minutes.toString().padStart(2, '0')} ${period}`;
    }
    return timeStr;
  } catch {
    return timeStr || '';
  }
}

export function formatRelative(dateStr?: string | null): string {
  if (!dateStr) return '';
  try {
    const d = parseISO(dateStr);
    if (!isValid(d)) return dateStr;
    return formatDistanceToNow(d, { addSuffix: true });
  } catch {
    return dateStr || '';
  }
}

export function formatCompactDateLine(item: ViewerItem): string {
  if ('event_date' in item) {
    // Schedule item
    const sched = item as ScheduleItem;
    const dateFormatted = formatDateTime(sched.event_date, 'MMM d');
    if (sched.all_day) {
      return `${dateFormatted} · All Day`;
    }
    if (sched.start_time && sched.end_time) {
      return `${dateFormatted} · ${formatTime(sched.start_time)} - ${formatTime(sched.end_time)}`;
    }
    if (sched.start_time) {
      return `${dateFormatted} · ${formatTime(sched.start_time)}`;
    }
    return dateFormatted;
  } else {
    // Solicitation item
    const solic = item as SolicitationItem;
    const parts: string[] = [];
    if (solic.requested_date) {
      parts.push(`Made ${formatDateTime(solic.requested_date, 'MMM d')}`);
    }
    if (solic.deadline) {
      parts.push(`Due ${formatDateTime(solic.deadline, 'MMM d')}`);
    }
    if (solic.given_date) {
      parts.push(`Given ${formatDateTime(solic.given_date, 'MMM d')}`);
    }
    return parts.length > 0 ? parts.join(' · ') : formatDateTime(item.created_at, 'MMM d');
  }
}

export function formatCurrency(amount?: number | null, masked: boolean = false): string {
  if (masked) return '••••••';
  if (amount == null) return '';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(amount);
}

export function isItemOverdue(item: ViewerItem): boolean {
  const now = new Date();
  if ('event_date' in item) {
    const sched = item as ScheduleItem;
    if (sched.status === 'Done' || sched.status === 'Cancelled' || sched.status === 'Past') {
      return false;
    }
    if (!sched.event_date) return false;
    try {
      const eventDate = parseISO(sched.event_date);
      return isBefore(eventDate, now);
    } catch {
      return false;
    }
  } else {
    const solic = item as SolicitationItem;
    if (solic.status === 'Done' || solic.status === 'Given' || solic.status === 'Declined' || solic.status === 'Cancelled') {
      return false;
    }
    if (!solic.deadline) return false;
    try {
      const deadlineDate = parseISO(solic.deadline);
      return isBefore(deadlineDate, now);
    } catch {
      return false;
    }
  }
}

export function getStatusColor(statusStr: string): string {
  const key = statusStr.toLowerCase() as keyof typeof TOKENS.colors.statuses;
  return TOKENS.colors.statuses[key] || '#78909C';
}

export function getPriorityColor(priorityStr: Priority): string {
  return TOKENS.colors.priorities[priorityStr] || '#FFA726';
}

export function getPriorityLabel(priorityStr: Priority): string {
  switch (priorityStr) {
    case 'low':
      return 'Low Priority';
    case 'medium':
      return 'Medium Priority';
    case 'high':
      return 'High Priority';
    case 'urgent':
      return 'Urgent Priority';
    default:
      return priorityStr;
  }
}

export function buildFilterQuery(params: Record<string, any>): string {
  const query = new URLSearchParams();
  for (const [key, val] of Object.entries(params)) {
    if (val === undefined || val === null || val === '') continue;
    if (Array.isArray(val)) {
      if (val.length > 0) {
        query.set(key, val.join(','));
      }
    } else if (typeof val === 'object') {
      query.set(key, JSON.stringify(val));
    } else {
      query.set(key, String(val));
    }
  }
  return query.toString();
}

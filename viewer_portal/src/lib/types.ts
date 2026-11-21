export type ScheduleStatus = 'Active' | 'Done' | 'Cancelled' | 'Past';

export type SolicitationStatus =
  | 'Draft'
  | 'Sent'
  | 'Pending'
  | 'Approved'
  | 'Declined'
  | 'Given'
  | 'Done'
  | 'Cancelled';

export type Priority = 'low' | 'medium' | 'high' | 'urgent';

export interface Attachment {
  id: string;
  item_id: string;
  module: 'schedule' | 'solicitation';
  file_path: string;
  file_name: string;
  file_size?: number;
  file_type?: string;
  purpose?: string;
  ocr_text?: string;
  url?: string;
}

export interface AuditLogEntry {
  id: string;
  item_id: string;
  module: 'schedule' | 'solicitation';
  action: string;
  field?: string;
  old_value?: string;
  new_value?: string;
  timestamp: string;
  actor: string;
  source?: string;
}

export interface BaseItem {
  id: string;
  title: string;
  notes?: string;
  priority: Priority;
  category?: string;
  location?: string;
  created_at: string;
  updated_at: string;
  is_deleted?: boolean;
  attachments?: Attachment[];
  audit_logs?: AuditLogEntry[];
}

export interface ScheduleItem extends BaseItem {
  description?: string;
  event_date: string;
  start_time?: string;
  end_time?: string;
  all_day?: boolean;
  repeat_rule?: string;
  reminder_offsets?: number[];
  status: ScheduleStatus;
  actual_start?: string;
  actual_end?: string;
  source_date?: string;
}

export interface SolicitationItem extends BaseItem {
  organization?: string;
  contact_person?: string;
  phone?: string;
  email?: string;
  purpose?: string;
  amount_requested?: number;
  quantity_requested?: string;
  requested_date?: string;
  deadline?: string;
  follow_up_date?: string;
  status: SolicitationStatus;
  given_date?: string;
  given_amount?: number;
  given_item?: string;
  given_by?: string;
  given_to?: string;
  receipt_proof?: string;
  source_date?: string;
}

export type ViewerItem = ScheduleItem | SolicitationItem;

export interface PrivacyControls {
  mask_amounts?: boolean;
  hide_contact_info?: boolean;
  hide_internal_notes?: boolean;
  hide_audit_trail?: boolean;
  strip_attachments?: boolean;
  allowed_fields?: string[];
}

export interface ShareScope {
  modules: ('schedule' | 'solicitation')[];
  categories?: string[];
  status_filter?: string[];
  date_from?: string;
  date_to?: string;
  item_ids?: string[];
}

export interface ShareLink {
  token: string;
  label?: string;
  scope: ShareScope;
  expires_at?: string;
  view_limit?: number;
  view_count?: number;
  privacy_controls: PrivacyControls;
  allow_export: boolean;
  is_revoked: boolean;
  requires_passcode?: boolean;
}

export interface ViewerContext {
  token: string;
  jwtToken?: string;
  scope: ShareScope;
  privacyControls: PrivacyControls;
  allowExport: boolean;
  label?: string;
  expiresAt?: string;
  requiresPasscode?: boolean;
}

export type ViewMode = 'list' | 'calendar' | 'agenda';
export type TabModule = 'schedule' | 'solicitation';
export type StatusTab = 'active' | 'history';

export type GroupBy = 'none' | 'date' | 'category' | 'status' | 'priority';

export type SortField = 'date' | 'priority' | 'title' | 'status' | 'amount';
export type SortDirection = 'asc' | 'desc';

export interface SortState {
  field: SortField;
  direction: SortDirection;
}

export type TimeFilterMode = 'all' | 'day' | 'month' | 'year' | 'custom';

export interface FilterState {
  search?: string;
  categories: string[];
  statuses: string[];
  priorities: Priority[];
  timeMode?: TimeFilterMode;
  timeAnchor?: string;
  dateRange?: {
    from?: string;
    to?: string;
  };
  dayOfWeek?: number[];
  monthYear?: {
    month: number; // 0-11
    year: number;
  };
  onlyOverdue?: boolean;
}

export interface PaginationState {
  page: number;
  limit: number;
  total: number;
  hasMore: boolean;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
}

export interface TokenValidationResponse {
  valid: boolean;
  requiresPasscode?: boolean;
  rateLimited?: boolean;
  expired?: boolean;
  revoked?: boolean;
  error?: string;
  token?: string;
  jwt?: string;
  scope?: ShareScope;
  privacyControls?: PrivacyControls;
  allowExport?: boolean;
  label?: string;
  expiresAt?: string;
}

export interface SSEUpdatePayload {
  type: 'initial' | 'insert' | 'update' | 'delete' | 'sync';
  module: 'schedule' | 'solicitation';
  itemId?: string;
  data?: ViewerItem;
  timestamp: string;
}

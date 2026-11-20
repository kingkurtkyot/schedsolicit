import {
  PaginatedResponse,
  ScheduleItem,
  SolicitationItem,
  TokenValidationResponse,
  ViewerItem,
} from './types';

export function getApiBaseUrl(): string {
  if (process.env.NEXT_PUBLIC_API_URL) {
    return process.env.NEXT_PUBLIC_API_URL.replace(/\/$/, '');
  }
  if (typeof window !== 'undefined') {
    // In browser: dynamically use window.location.origin (supports LAN IPs, custom domains, and Nginx proxy)
    return window.location.origin;
  }
  return process.env.INTERNAL_API_URL || 'http://localhost:8000';
}

class ApiClient {
  private jwtToken: string | null = null;

  setJwtToken(jwt: string | null) {
    this.jwtToken = jwt;
    if (typeof window !== 'undefined') {
      if (jwt) {
        sessionStorage.setItem('schedsolicit_viewer_jwt', jwt);
      } else {
        sessionStorage.removeItem('schedsolicit_viewer_jwt');
      }
    }
  }

  getJwtToken(): string | null {
    if (this.jwtToken) return this.jwtToken;
    if (typeof window !== 'undefined') {
      this.jwtToken = sessionStorage.getItem('schedsolicit_viewer_jwt');
    }
    return this.jwtToken;
  }

  private async fetchWithRetry<T>(
    endpoint: string,
    options: RequestInit = {},
    retries = 2,
    delayMs = 1000
  ): Promise<T> {
    const url = `${getApiBaseUrl()}${endpoint}`;
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...((options.headers as Record<string, string>) || {}),
    };

    const jwt = this.getJwtToken();
    if (jwt && !headers['Authorization']) {
      headers['Authorization'] = `Bearer ${jwt}`;
    }

    try {
      const response = await fetch(url, {
        ...options,
        headers,
      });

      if (!response.ok) {
        if (response.status === 429) {
          const err = new Error('Rate limit exceeded. Please wait a moment.');
          (err as any).status = 429;
          throw err;
        }
        if (response.status === 401 || response.status === 403) {
          const err = new Error('Access denied or link expired.');
          (err as any).status = response.status;
          throw err;
        }

        if (retries > 0 && response.status >= 500) {
          await new Promise((resolve) => setTimeout(resolve, delayMs));
          return this.fetchWithRetry<T>(endpoint, options, retries - 1, delayMs * 2);
        }

        const errData = await response.json().catch(() => ({}));
        throw new Error(errData.detail || errData.message || `Request failed (${response.status})`);
      }

      return (await response.json()) as T;
    } catch (err: any) {
      if (retries > 0 && (err.name === 'TypeError' || err.message === 'Failed to fetch')) {
        await new Promise((resolve) => setTimeout(resolve, delayMs));
        return this.fetchWithRetry<T>(endpoint, options, retries - 1, delayMs * 2);
      }
      throw err;
    }
  }

  async validateToken(token: string, passcode?: string): Promise<TokenValidationResponse> {
    try {
      const result = await this.fetchWithRetry<TokenValidationResponse>(
        '/api/view/auth/validate',
        {
          method: 'POST',
          body: JSON.stringify({ token, passcode }),
        },
        1
      );
      const raw = result as any;
      const jwt = raw.viewer_token || raw.jwt || raw.token;
      if (jwt) {
        this.setJwtToken(jwt);
        result.jwt = jwt;
        result.valid = true;
      }
      return result;
    } catch (err: any) {
      return {
        valid: false,
        error: err.message,
        rateLimited: err.status === 429,
        revoked: err.status === 403,
      };
    }
  }

  async getSchedules(
    token: string,
    params: {
      status_type?: 'active' | 'history';
      page?: number;
      limit?: number;
      search?: string;
      category?: string[];
      priority?: string[];
      date_from?: string;
      date_to?: string;
      sort_by?: string;
      sort_dir?: 'asc' | 'desc';
    } = {}
  ): Promise<PaginatedResponse<ScheduleItem>> {
    const q = new URLSearchParams({ token });
    if (params.status_type) q.set('status_type', params.status_type);
    if (params.page) q.set('page', params.page.toString());
    if (params.limit) q.set('limit', params.limit.toString());
    if (params.search) q.set('search', params.search);
    if (params.sort_by) q.set('sort_by', params.sort_by);
    if (params.sort_dir) q.set('sort_dir', params.sort_dir);
    if (params.category && params.category.length > 0) {
      q.set('categories', params.category.join(','));
    }
    if (params.priority && params.priority.length > 0) {
      q.set('priorities', params.priority.join(','));
    }
    if (params.date_from) q.set('date_from', params.date_from);
    if (params.date_to) q.set('date_to', params.date_to);

    return this.fetchWithRetry<PaginatedResponse<ScheduleItem>>(
      `/api/view/schedules?${q.toString()}`
    );
  }

  async getSolicitations(
    token: string,
    params: {
      status_type?: 'active' | 'history';
      page?: number;
      limit?: number;
      search?: string;
      category?: string[];
      priority?: string[];
      date_from?: string;
      date_to?: string;
      sort_by?: string;
      sort_dir?: 'asc' | 'desc';
    } = {}
  ): Promise<PaginatedResponse<SolicitationItem>> {
    const q = new URLSearchParams({ token });
    if (params.status_type) q.set('status_type', params.status_type);
    if (params.page) q.set('page', params.page.toString());
    if (params.limit) q.set('limit', params.limit.toString());
    if (params.search) q.set('search', params.search);
    if (params.sort_by) q.set('sort_by', params.sort_by);
    if (params.sort_dir) q.set('sort_dir', params.sort_dir);
    if (params.category && params.category.length > 0) {
      q.set('categories', params.category.join(','));
    }
    if (params.priority && params.priority.length > 0) {
      q.set('priorities', params.priority.join(','));
    }
    if (params.date_from) q.set('date_from', params.date_from);
    if (params.date_to) q.set('date_to', params.date_to);

    return this.fetchWithRetry<PaginatedResponse<SolicitationItem>>(
      `/api/view/solicitations?${q.toString()}`
    );
  }

  async getItemDetail(
    token: string,
    module: 'schedule' | 'solicitation',
    id: string
  ): Promise<ViewerItem> {
    const q = new URLSearchParams({ token, module, id });
    return this.fetchWithRetry<ViewerItem>(`/api/view/item?${q.toString()}`);
  }

  async search(token: string, query: string): Promise<{ schedules: ScheduleItem[]; solicitations: SolicitationItem[] }> {
    const q = new URLSearchParams({ token, q: query });
    return this.fetchWithRetry<{ schedules: ScheduleItem[]; solicitations: SolicitationItem[] }>(
      `/api/view/search?${q.toString()}`
    );
  }

  async getExport(token: string, format: 'png' | 'pdf' | 'ics' | 'csv' | 'xlsx'): Promise<Blob> {
    const url = `${getApiBaseUrl()}/api/view/export?token=${token}&format=${format}`;
    const jwt = this.getJwtToken();
    const headers: Record<string, string> = {};
    if (jwt) {
      headers['Authorization'] = `Bearer ${jwt}`;
    }
    const res = await fetch(url, { headers });
    if (!res.ok) {
      throw new Error(`Export failed (${res.status})`);
    }
    return await res.blob();
  }

  getIcsFeedUrl(token: string): string {
    return `${getApiBaseUrl()}/api/view/ics?token=${token}`;
  }
}

export const api = new ApiClient();

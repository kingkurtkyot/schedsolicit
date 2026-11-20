import React from 'react';
import { redirect } from 'next/navigation';
import { Badge } from '@/components/ui/Badge';
import { ExportButton } from '@/components/ExportButton';
import { TokenValidationResponse } from '@/lib/types';
import Link from 'next/link';
import { Calendar } from 'lucide-react';

interface TokenLayoutProps {
  children: React.ReactNode;
  params: {
    token: string;
  };
}

async function validateShareToken(token: string): Promise<TokenValidationResponse> {
  if (token === 'local') {
    return {
      valid: true,
      label: 'Local Shared Portal',
      scope: { modules: ['schedule', 'solicitation'] },
      allowExport: true,
    };
  }

  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
  try {
    const res = await fetch(`${apiUrl}/api/view/auth/validate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token }),
      cache: 'no-store',
    });

    if (!res.ok) {
      if (res.status === 429) return { valid: false, rateLimited: true };
      if (res.status === 403) return { valid: false, revoked: true };
      return { valid: false, error: 'Token validation failed' };
    }

    const data = await res.json();
    return { valid: true, ...data };
  } catch (err: any) {
    // If backend is unreachable, allow rendering with local dataset
    return {
      valid: true,
      label: 'Shared Portal (Offline)',
      scope: { modules: ['schedule', 'solicitation'] },
      allowExport: true,
    };
  }
}

export default async function TokenLayout({ children, params }: TokenLayoutProps) {
  const { token } = params;
  const validation = await validateShareToken(token);

  if (!validation.valid && token !== 'local') {
    if (validation.requiresPasscode) {
      redirect(`/passcode?token=${encodeURIComponent(token)}`);
    } else if (validation.rateLimited) {
      redirect(`/error?type=rate-limited`);
    } else if (validation.revoked) {
      redirect(`/error?type=revoked`);
    } else if (validation.expired) {
      redirect(`/error?type=expired`);
    } else {
      redirect(`/error?type=invalid`);
    }
  }

  const allowExport = validation.allowExport ?? true;
  const label = validation.label || 'Shared Portal';

  return (
    <div className="min-h-[100dvh] flex flex-col bg-[var(--surface-bg)] text-[var(--text-primary)]">
      {/* Top Header */}
      <header className="sticky top-0 z-30 bg-[var(--surface-card)]/90 backdrop-blur-md border-b border-[var(--surface-border-subtle)] px-4 py-3 sm:px-6">
        <div className="max-w-7xl mx-auto flex items-center justify-between gap-3">
          <div className="flex items-center gap-2.5">
            <Link
              href="/"
              className="flex items-center gap-2 text-[var(--color-seed)] font-black text-lg tracking-tight hover:opacity-90 transition-opacity"
            >
              <div className="w-8 h-8 rounded-lg bg-[var(--color-seed)] text-white flex items-center justify-center shadow-xs">
                <Calendar className="w-4 h-4" />
              </div>
              <span className="hidden sm:inline">SchedSolicit</span>
            </Link>

            <span className="text-xs font-semibold text-[var(--text-muted)] truncate max-w-[140px] sm:max-w-xs">
              {label}
            </span>
          </div>

          <div className="flex items-center gap-2 sm:gap-3">
            <Badge variant="viewOnly" />
            <ExportButton token={token} allowExport={allowExport} />
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-3 sm:p-6 pb-24 desktop:pb-6">
        {children}
      </main>
    </div>
  );
}

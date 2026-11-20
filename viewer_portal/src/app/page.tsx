'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Calendar, Shield, ExternalLink, ArrowRight } from 'lucide-react';
import { cn } from '@/lib/utils';

export default function LandingPage() {
  const router = useRouter();
  const [tokenInput, setTokenInput] = useState('');

  const handleOpenLink = (e: React.FormEvent) => {
    e.preventDefault();
    if (!tokenInput.trim()) return;

    // Handle full URL paste or raw token
    let cleanToken = tokenInput.trim();
    if (cleanToken.includes('/')) {
      const parts = cleanToken.split('/');
      cleanToken = parts[parts.length - 1] || parts[parts.length - 2];
    }

    router.push(`/${cleanToken}`);
  };

  return (
    <main className="flex min-h-[100dvh] flex-col items-center justify-center px-4 py-12">
      <div className="w-full max-w-md p-6 sm:p-8 rounded-3xl bg-[var(--surface-card)] border border-[var(--surface-border-subtle)] shadow-xl text-center space-y-8">
        {/* Brand Icon & Heading */}
        <div className="space-y-3">
          <div className="w-16 h-16 mx-auto rounded-2xl bg-[var(--color-seed)] text-white flex items-center justify-center shadow-lg shadow-green-900/10">
            <Calendar className="w-8 h-8" />
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold text-[var(--text-primary)]">
            SchedSolicit
          </h1>
          <p className="text-sm text-[var(--text-secondary)] max-w-xs mx-auto">
            Secure, live viewer portal for shared schedules and solicitation requests.
          </p>
        </div>

        {/* Token Link Form */}
        <form onSubmit={handleOpenLink} className="space-y-4">
          <div className="text-left space-y-1">
            <label
              htmlFor="tokenInput"
              className="text-xs font-bold text-[var(--text-muted)] uppercase tracking-wider block"
            >
              Have a share link or token?
            </label>
            <input
              id="tokenInput"
              type="text"
              value={tokenInput}
              onChange={(e) => setTokenInput(e.target.value)}
              placeholder="Paste link or token here"
              className={cn(
                'w-full px-4 py-3 rounded-xl text-base sm:text-sm',
                'bg-[var(--surface-container)] text-[var(--text-primary)] border border-[var(--surface-border)]',
                'focus:border-[var(--color-seed)] focus:outline-none focus:ring-2 focus:ring-[var(--color-seed)]/20',
                'min-h-[48px]'
              )}
            />
          </div>

          <button
            type="submit"
            disabled={!tokenInput.trim()}
            className={cn(
              'w-full py-3.5 px-5 rounded-xl text-sm font-bold text-white transition-all shadow-md',
              'bg-[var(--color-seed)] hover:bg-[var(--color-forest)] active:scale-95',
              'disabled:opacity-50 disabled:pointer-events-none min-h-[48px] flex items-center justify-center gap-2'
            )}
          >
            <span>View Portal</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </form>

        {/* Feature Highlights */}
        <div className="pt-4 border-t border-[var(--surface-border-subtle)] grid grid-cols-2 gap-3 text-left">
          <div className="flex items-start gap-2">
            <Shield className="w-4 h-4 text-[var(--color-seed)] mt-0.5 flex-shrink-0" />
            <span className="text-xs text-[var(--text-muted)]">
              Read-only & privacy preserved
            </span>
          </div>
          <div className="flex items-start gap-2">
            <ExternalLink className="w-4 h-4 text-[var(--color-seed)] mt-0.5 flex-shrink-0" />
            <span className="text-xs text-[var(--text-muted)]">
              Live updates via real-time stream
            </span>
          </div>
        </div>
      </div>
    </main>
  );
}

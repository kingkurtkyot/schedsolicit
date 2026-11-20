'use client';

import React, { useState } from 'react';
import { Lock, Loader2, AlertCircle } from 'lucide-react';
import { cn } from '@/lib/utils';

interface PasscodeEntryProps {
  token: string;
  onSubmit: (passcode: string) => Promise<void>;
  loading?: boolean;
  errorMessage?: string | null;
  rateLimited?: boolean;
}

export const PasscodeEntry: React.FC<PasscodeEntryProps> = ({
  token,
  onSubmit,
  loading = false,
  errorMessage,
  rateLimited = false,
}) => {
  const [passcode, setPasscode] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!passcode || loading || rateLimited) return;
    await onSubmit(passcode);
  };

  const handleDigitClick = (digit: string) => {
    if (passcode.length < 8 && !loading && !rateLimited) {
      setPasscode((prev) => prev + digit);
    }
  };

  const handleBackspace = () => {
    if (!loading && !rateLimited) {
      setPasscode((prev) => prev.slice(0, -1));
    }
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-[70dvh] px-4 max-w-sm mx-auto">
      <div className="w-full p-6 sm:p-8 rounded-2xl bg-[var(--surface-card)] border border-[var(--surface-border-subtle)] shadow-xl text-center space-y-6">
        {/* Icon */}
        <div className="w-14 h-14 mx-auto rounded-full bg-[var(--color-seed)]/15 flex items-center justify-center text-[var(--color-seed)]">
          <Lock className="w-7 h-7" />
        </div>

        {/* Title */}
        <div className="space-y-1">
          <h2 className="text-xl font-bold text-[var(--text-primary)]">Passcode Required</h2>
          <p className="text-xs text-[var(--text-muted)]">
            This shared link is protected. Enter the PIN or passcode to view.
          </p>
        </div>

        {/* Error message */}
        {errorMessage && (
          <div className="flex items-center gap-2 p-3 rounded-xl bg-red-100 dark:bg-red-950/60 border border-red-300 dark:border-red-900 text-red-700 dark:text-red-300 text-xs font-semibold text-left">
            <AlertCircle className="w-4 h-4 flex-shrink-0" />
            <span>{errorMessage}</span>
          </div>
        )}

        {/* Passcode input form */}
        <form onSubmit={handleSubmit} className="space-y-5">
          <div className="flex justify-center">
            <input
              type="password"
              inputMode="numeric"
              maxLength={8}
              autoFocus
              value={passcode}
              onChange={(e) => setPasscode(e.target.value)}
              placeholder="••••"
              disabled={loading || rateLimited}
              className={cn(
                'w-48 text-center text-2xl tracking-[0.5em] font-mono py-2.5 rounded-xl',
                'bg-[var(--surface-container)] text-[var(--text-primary)] border border-[var(--surface-border)]',
                'focus:border-[var(--color-seed)] focus:outline-none focus:ring-2 focus:ring-[var(--color-seed)]/30',
                'min-h-[48px]'
              )}
            />
          </div>

          {/* Keypad for mobile touch */}
          <div className="grid grid-cols-3 gap-2 max-w-xs mx-auto">
            {['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '⌫'].map((k) => (
              <button
                key={k}
                type="button"
                onClick={() => {
                  if (k === 'C') setPasscode('');
                  else if (k === '⌫') handleBackspace();
                  else handleDigitClick(k);
                }}
                disabled={loading || rateLimited}
                className={cn(
                  'h-12 rounded-xl text-base font-bold transition-all',
                  'bg-[var(--surface-container)] text-[var(--text-primary)] hover:bg-[var(--surface-border-subtle)] active:scale-95',
                  'flex items-center justify-center select-none min-h-[44px]'
                )}
              >
                {k}
              </button>
            ))}
          </div>

          <button
            type="submit"
            disabled={loading || !passcode || rateLimited}
            className={cn(
              'w-full py-3 px-4 rounded-xl text-sm font-bold text-white transition-all shadow-md',
              'bg-[var(--color-seed)] hover:bg-[var(--color-forest)] active:scale-95',
              'disabled:opacity-50 disabled:pointer-events-none min-h-[44px] flex items-center justify-center gap-2'
            )}
          >
            {loading ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Verifying...</span>
              </>
            ) : (
              <span>Unlock</span>
            )}
          </button>
        </form>
      </div>
    </div>
  );
};

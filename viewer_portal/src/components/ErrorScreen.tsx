'use client';

import React from 'react';
import { AlertCircle, Clock, ShieldAlert, Ban, RefreshCw } from 'lucide-react';
import { Card } from './ui/Card';
import { cn } from '@/lib/utils';

export type ErrorType = 'expired' | 'revoked' | 'invalid' | 'rate-limited' | 'unknown';

interface ErrorScreenProps {
  type: ErrorType;
  message?: string;
  onRetry?: () => void;
}

export const ErrorScreen: React.FC<ErrorScreenProps> = ({ type, message, onRetry }) => {
  const getErrorConfig = () => {
    switch (type) {
      case 'expired':
        return {
          icon: <Clock className="w-10 h-10 text-amber-500" />,
          title: 'Link Expired',
          desc: message || 'This shared link has expired and is no longer accessible. Please request a new link from the sender.',
        };
      case 'revoked':
        return {
          icon: <Ban className="w-10 h-10 text-red-500" />,
          title: 'Link Revoked',
          desc: message || 'This shared link was revoked by the owner. Access is no longer permitted.',
        };
      case 'rate-limited':
        return {
          icon: <ShieldAlert className="w-10 h-10 text-orange-500" />,
          title: 'Too Many Attempts',
          desc: message || 'Too many passcode attempts. Access is locked for 15 minutes to protect security.',
        };
      case 'invalid':
      default:
        return {
          icon: <AlertCircle className="w-10 h-10 text-red-500" />,
          title: 'Invalid Link',
          desc: message || 'The requested link was not found or contains an invalid access token.',
        };
    }
  };

  const { icon, title, desc } = getErrorConfig();

  return (
    <div className="flex flex-col items-center justify-center min-h-[60dvh] px-4 max-w-md mx-auto text-center">
      <Card mode="expanded" className="w-full space-y-6 p-8 shadow-xl">
        <div className="w-16 h-16 mx-auto rounded-full bg-[var(--surface-container)] flex items-center justify-center">
          {icon}
        </div>

        <div className="space-y-2">
          <h2 className="text-xl font-extrabold text-[var(--text-primary)]">{title}</h2>
          <p className="text-xs text-[var(--text-muted)] leading-relaxed">{desc}</p>
        </div>

        {onRetry && (
          <button
            type="button"
            onClick={onRetry}
            className={cn(
              'inline-flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl text-xs font-bold text-white transition-all',
              'bg-[var(--color-seed)] hover:bg-[var(--color-forest)] active:scale-95 shadow-xs min-h-[44px]'
            )}
          >
            <RefreshCw className="w-4 h-4" />
            <span>Try Again</span>
          </button>
        )}
      </Card>
    </div>
  );
};

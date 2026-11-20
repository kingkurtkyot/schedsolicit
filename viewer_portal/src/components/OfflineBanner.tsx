'use client';

import React from 'react';
import { WifiOff } from 'lucide-react';
import { cn } from '@/lib/utils';

interface OfflineBannerProps {
  isOffline: boolean;
  className?: string;
}

export const OfflineBanner: React.FC<OfflineBannerProps> = ({ isOffline, className }) => {
  if (!isOffline) return null;

  return (
    <div
      role="status"
      aria-live="polite"
      className={cn(
        'sticky top-0 z-50 flex items-center justify-center gap-2 px-4 py-2 text-xs font-semibold',
        'bg-amber-600 text-white shadow-md transition-all duration-300',
        className
      )}
    >
      <WifiOff className="w-4 h-4 animate-bounce" />
      <span>Offline — showing saved data</span>
    </div>
  );
};

'use client';

import React, { useState, useEffect } from 'react';
import { formatDistanceToNow } from 'date-fns';
import { Badge } from './ui/Badge';
import { cn } from '@/lib/utils';

interface LastUpdatedProps {
  lastUpdated: Date | null;
  isPulsing?: boolean;
  className?: string;
}

export const LastUpdated: React.FC<LastUpdatedProps> = ({
  lastUpdated,
  isPulsing = false,
  className,
}) => {
  const [timeAgo, setTimeAgo] = useState('Just now');

  useEffect(() => {
    const updateText = () => {
      if (!lastUpdated) {
        setTimeAgo('Live');
        return;
      }
      try {
        const text = formatDistanceToNow(lastUpdated, { addSuffix: true });
        setTimeAgo(text);
      } catch {
        setTimeAgo('Recently');
      }
    };

    updateText();
    const interval = setInterval(updateText, 30000); // refresh every 30s
    return () => clearInterval(interval);
  }, [lastUpdated]);

  return (
    <div className={cn('flex items-center gap-2 text-xs text-[var(--text-muted)]', className)}>
      {isPulsing && <Badge variant="updated" pulsing />}
      <span className="hidden sm:inline">Last updated: {timeAgo}</span>
    </div>
  );
};

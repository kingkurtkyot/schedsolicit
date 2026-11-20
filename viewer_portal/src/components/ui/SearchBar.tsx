'use client';

import React, { useState, useEffect, useRef } from 'react';
import { Search, X, Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';

interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  className?: string;
}

export const SearchBar: React.FC<SearchBarProps> = ({
  value,
  onChange,
  placeholder = 'Search items...',
  className,
}) => {
  const [localVal, setLocalVal] = useState(value);
  const debounceTimer = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    setLocalVal(value);
  }, [value]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value;
    setLocalVal(val);

    if (debounceTimer.current) {
      clearTimeout(debounceTimer.current);
    }

    debounceTimer.current = setTimeout(() => {
      onChange(val);
    }, 250);
  };

  const handleClear = () => {
    setLocalVal('');
    onChange('');
  };

  return (
    <div className={cn('relative flex items-center w-full', className)}>
      <Search className="absolute left-3 w-4 h-4 text-[var(--text-muted)] pointer-events-none" />
      <input
        type="text"
        value={localVal}
        onChange={handleChange}
        placeholder={placeholder}
        // Critical for iOS Safari: fontSize >= 16px prevents automatic browser zoom!
        className={cn(
          'w-full pl-9 pr-9 py-2.5 text-base sm:text-sm rounded-xl',
          'bg-[var(--surface-container)] text-[var(--text-primary)] placeholder-[var(--text-muted)]',
          'border border-[var(--surface-border-subtle)] focus:border-[var(--color-seed)] focus:outline-none focus:ring-1 focus:ring-[var(--color-seed)]',
          'transition-all duration-150 min-h-[44px]'
        )}
      />
      {localVal && (
        <button
          type="button"
          onClick={handleClear}
          aria-label="Clear search"
          className="absolute right-2.5 p-1 rounded-full text-[var(--text-muted)] hover:text-[var(--text-primary)] active:scale-90"
        >
          <X className="w-4 h-4" />
        </button>
      )}
    </div>
  );
};

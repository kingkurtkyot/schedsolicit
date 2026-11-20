'use client';

import React, { useState } from 'react';
import { api } from '@/lib/api';
import { Download, Loader2, FileSpreadsheet, FileCode, Calendar } from 'lucide-react';
import { cn } from '@/lib/utils';

interface ExportButtonProps {
  token: string;
  allowExport: boolean;
  className?: string;
}

export const ExportButton: React.FC<ExportButtonProps> = ({
  token,
  allowExport,
  className,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const [downloading, setDownloading] = useState(false);

  if (!allowExport) return null;

  const handleExport = async (format: 'png' | 'pdf' | 'ics' | 'csv' | 'xlsx') => {
    setDownloading(true);
    try {
      const blob = await api.getExport(token, format);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `schedsolicit_export_${new Date().toISOString().split('T')[0]}.${format}`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
      setIsOpen(false);
    } catch (err: any) {
      alert(`Export failed: ${err.message}`);
    } finally {
      setDownloading(false);
    }
  };

  return (
    <div className={cn('relative inline-block text-left', className)}>
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        disabled={downloading}
        aria-label="Download export"
        className={cn(
          'inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold transition-all',
          'bg-[var(--surface-container)] text-[var(--color-seed)] border border-[var(--surface-border-subtle)]',
          'hover:bg-[var(--surface-card)] active:scale-95 touch:min-h-[44px] shadow-xs'
        )}
      >
        {downloading ? (
          <Loader2 className="w-4 h-4 animate-spin" />
        ) : (
          <Download className="w-4 h-4" />
        )}
        <span className="hidden sm:inline">Export</span>
      </button>

      {isOpen && (
        <>
          <div
            className="fixed inset-0 z-30"
            onClick={() => setIsOpen(false)}
          />
          <div className="absolute right-0 mt-2 w-44 rounded-xl bg-[var(--surface-card)] border border-[var(--surface-border-subtle)] shadow-xl z-40 py-1 overflow-hidden animate-in fade-in zoom-in-95">
            <button
              type="button"
              onClick={() => handleExport('pdf')}
              className="flex items-center gap-2.5 w-full px-4 py-2.5 text-xs text-[var(--text-primary)] hover:bg-[var(--surface-container)] text-left min-h-[44px]"
            >
              <FileCode className="w-4 h-4 text-red-500" />
              <span>Export PDF Document</span>
            </button>
            <button
              type="button"
              onClick={() => handleExport('ics')}
              className="flex items-center gap-2.5 w-full px-4 py-2.5 text-xs text-[var(--text-primary)] hover:bg-[var(--surface-container)] text-left min-h-[44px]"
            >
              <Calendar className="w-4 h-4 text-blue-500" />
              <span>Export Calendar (ICS)</span>
            </button>
            <button
              type="button"
              onClick={() => handleExport('xlsx')}
              className="flex items-center gap-2.5 w-full px-4 py-2.5 text-xs text-[var(--text-primary)] hover:bg-[var(--surface-container)] text-left min-h-[44px]"
            >
              <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
              <span>Export Spreadsheet</span>
            </button>
          </div>
        </>
      )}
    </div>
  );
};

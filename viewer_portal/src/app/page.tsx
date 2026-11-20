'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Calendar, Shield, ExternalLink, ArrowRight, Sparkles, KeyRound, UploadCloud } from 'lucide-react';
import { decodeSharePayload, SharedDataset } from '@/lib/payload';
import { cn } from '@/lib/utils';

export default function LandingPage() {
  const router = useRouter();
  const [tokenInput, setTokenInput] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Auto-detect #d= or ?d= payload on page mount
  useEffect(() => {
    if (typeof window === 'undefined') return;

    const hash = window.location.hash;
    const search = window.location.search;
    let payload = '';

    if (hash.includes('d=')) {
      payload = hash.split('d=')[1];
    } else if (search.includes('d=')) {
      payload = new URLSearchParams(search).get('d') || '';
    }

    if (payload) {
      setIsProcessing(true);
      decodeSharePayload(payload).then((dataset) => {
        if (dataset) {
          localStorage.setItem('schedsolicit_dataset', JSON.stringify(dataset));
          router.push('/local');
        } else {
          setIsProcessing(false);
          setErrorMessage('Could not decode shared package from link.');
        }
      });
    }
  }, [router]);

  const handleOpenLink = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!tokenInput.trim()) return;

    setErrorMessage(null);
    setIsProcessing(true);

    const input = tokenInput.trim();

    // 1. Try decoding as zero-backend standalone payload
    const dataset = await decodeSharePayload(input);
    if (dataset) {
      localStorage.setItem('schedsolicit_dataset', JSON.stringify(dataset));
      router.push('/local');
      return;
    }

    // 2. If it's a legacy server token or short ID
    let cleanToken = input;
    if (cleanToken.includes('/')) {
      const parts = cleanToken.split('/');
      cleanToken = parts[parts.length - 1] || parts[parts.length - 2];
    }

    router.push(`/${cleanToken}`);
  };

  const loadSampleData = () => {
    const sample: SharedDataset = {
      v: 1,
      label: 'Jia Jizelle Christening & Solicitations',
      exported_at: new Date().toISOString(),
      schedules: [
        {
          id: 'sample-1',
          title: 'Jia Jizelle - Christening Mass',
          description: 'Join us as we celebrate God’s blessing and the joy of our little one.',
          event_date: '2026-11-28',
          start_time: '8:00 AM',
          end_time: '10:00 AM',
          location: 'Diocesan Shrine & Parish of Saint Clement, Dona Aurora St., Poblacion Angono',
          category: 'Church',
          priority: 'high',
          status: 'Active',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
        {
          id: 'sample-2',
          title: 'Reception & Fellowship',
          description: 'Lunch and fellowship celebration for family and friends.',
          event_date: '2026-11-28',
          start_time: '11:00 AM',
          end_time: '3:00 PM',
          location: 'Bayabas St. Blooming Breeze Subd., Angono Rizal',
          category: 'Personal',
          priority: 'medium',
          status: 'Active',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
      ],
      solicitations: [
        {
          id: 'sample-3',
          title: 'St. Clement Parish Charity Donation',
          organization: 'Diocesan Parish Council',
          contact_person: 'Fr. Raymond',
          amount_requested: 5000.0,
          purpose: 'Support for church community outreach and christening assistance program',
          status: 'Draft',
          priority: 'medium',
          category: 'Donation',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
      ],
    };

    localStorage.setItem('schedsolicit_dataset', JSON.stringify(sample));
    router.push('/local');
  };

  return (
    <main className="flex min-h-[100dvh] flex-col items-center justify-center px-4 py-8 bg-[var(--surface-bg)]">
      <div className="w-full max-w-lg p-6 sm:p-8 rounded-3xl bg-[var(--surface-card)] border border-[var(--surface-border-subtle)] shadow-2xl text-center space-y-6">
        {/* Brand Icon & Heading */}
        <div className="space-y-3">
          <div className="w-16 h-16 mx-auto rounded-2xl bg-[var(--color-seed)] text-white flex items-center justify-center shadow-lg shadow-green-900/10">
            <Calendar className="w-8 h-8" />
          </div>
          <h1 className="text-2xl sm:text-3xl font-black text-[var(--text-primary)] tracking-tight">
            SchedSolicit
          </h1>
          <p className="text-xs sm:text-sm text-[var(--text-secondary)] max-w-sm mx-auto leading-relaxed">
            Zero-backend public viewer portal. Read-only schedules, agendas, and solicitations straight from the Owner App.
          </p>
        </div>

        {/* Token Link Form */}
        <form onSubmit={handleOpenLink} className="space-y-4">
          <div className="text-left space-y-1.5">
            <label
              htmlFor="tokenInput"
              className="text-xs font-bold text-[var(--text-muted)] uppercase tracking-wider flex items-center gap-1.5"
            >
              <KeyRound className="w-3.5 h-3.5 text-[var(--color-seed)]" />
              <span>Paste 1-Click Link or Encrypted Code</span>
            </label>
            <textarea
              id="tokenInput"
              rows={3}
              value={tokenInput}
              onChange={(e) => setTokenInput(e.target.value)}
              placeholder="Paste SS1_... code or viewer link here"
              className={cn(
                'w-full px-4 py-3 rounded-xl text-xs sm:text-sm font-mono',
                'bg-[var(--surface-container)] text-[var(--text-primary)] border border-[var(--surface-border)]',
                'focus:border-[var(--color-seed)] focus:outline-none focus:ring-2 focus:ring-[var(--color-seed)]/20',
                'resize-none'
              )}
            />
          </div>

          {errorMessage && (
            <p className="text-xs text-red-500 text-left font-medium">{errorMessage}</p>
          )}

          <button
            type="submit"
            disabled={!tokenInput.trim() || isProcessing}
            className={cn(
              'w-full py-3.5 px-5 rounded-xl text-sm font-bold text-white transition-all shadow-md',
              'bg-[var(--color-seed)] hover:bg-[var(--color-forest)] active:scale-95',
              'disabled:opacity-50 disabled:pointer-events-none min-h-[48px] flex items-center justify-center gap-2'
            )}
          >
            {isProcessing ? (
              <span>Unpacking shared dataset...</span>
            ) : (
              <>
                <span>Open Viewer Portal</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        {/* Demo Quick Button */}
        <div className="pt-2">
          <button
            type="button"
            onClick={loadSampleData}
            className="w-full py-2.5 px-4 rounded-xl text-xs font-semibold text-[var(--color-seed)] bg-[var(--surface-container)] hover:bg-[var(--surface-container-high)] border border-[var(--surface-border-subtle)] transition-all flex items-center justify-center gap-2"
          >
            <Sparkles className="w-4 h-4" />
            <span>Load Sample Demo (Christening Event & Solicitations)</span>
          </button>
        </div>

        {/* Feature Highlights */}
        <div className="pt-4 border-t border-[var(--surface-border-subtle)] grid grid-cols-2 gap-3 text-left">
          <div className="flex items-start gap-2">
            <Shield className="w-4 h-4 text-[var(--color-seed)] mt-0.5 flex-shrink-0" />
            <span className="text-xs text-[var(--text-muted)]">
              Zero backend required • 100% Client-Side Privacy
            </span>
          </div>
          <div className="flex items-start gap-2">
            <ExternalLink className="w-4 h-4 text-[var(--color-seed)] mt-0.5 flex-shrink-0" />
            <span className="text-xs text-[var(--text-muted)]">
              Instant load • Offline PWA Support on Mobile
            </span>
          </div>
        </div>
      </div>
    </main>
  );
}

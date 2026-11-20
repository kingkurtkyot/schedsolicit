'use client';

import React, { useState, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { PasscodeEntry } from '@/components/PasscodeEntry';
import { api } from '@/lib/api';

function PasscodeContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const token = searchParams.get('token') || '';

  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [rateLimited, setRateLimited] = useState(false);

  const handleSubmit = async (passcode: string) => {
    setLoading(true);
    setErrorMessage(null);

    try {
      const res = await api.validateToken(token, passcode);
      if (res.valid) {
        // Redirect to token main page
        router.push(`/${token}`);
      } else if (res.rateLimited) {
        setRateLimited(true);
        setErrorMessage('Too many passcode attempts. Access locked for 15 minutes.');
      } else {
        setErrorMessage(res.error || 'Incorrect passcode. Please try again.');
      }
    } catch (err: any) {
      setErrorMessage(err.message || 'Validation failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="min-h-[100dvh] flex items-center justify-center p-4">
      <PasscodeEntry
        token={token}
        onSubmit={handleSubmit}
        loading={loading}
        errorMessage={errorMessage}
        rateLimited={rateLimited}
      />
    </main>
  );
}

export default function PasscodePage() {
  return (
    <Suspense fallback={<div className="p-8 text-center text-xs">Loading...</div>}>
      <PasscodeContent />
    </Suspense>
  );
}

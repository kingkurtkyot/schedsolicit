'use client';

import React, { Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { ErrorScreen, ErrorType } from '@/components/ErrorScreen';

function ErrorContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const rawType = searchParams.get('type') || 'invalid';
  const message = searchParams.get('message') || undefined;

  const validTypes: ErrorType[] = ['expired', 'revoked', 'invalid', 'rate-limited'];
  const type: ErrorType = validTypes.includes(rawType as ErrorType)
    ? (rawType as ErrorType)
    : 'invalid';

  return (
    <main className="min-h-[100dvh] flex items-center justify-center p-4">
      <ErrorScreen
        type={type}
        message={message}
        onRetry={() => router.push('/')}
      />
    </main>
  );
}

export default function ErrorPage() {
  return (
    <Suspense fallback={<div className="p-8 text-center text-xs">Loading error screen...</div>}>
      <ErrorContent />
    </Suspense>
  );
}

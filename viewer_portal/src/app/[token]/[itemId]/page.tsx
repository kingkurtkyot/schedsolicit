'use client';

import React, { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import { ViewerItem } from '@/lib/types';
import { ItemDetail } from '@/components/ItemDetail';
import { SkeletonLoader } from '@/components/ui/SkeletonLoader';

export default function ItemDetailPage() {
  const params = useParams();
  const router = useRouter();

  const token = typeof params.token === 'string' ? params.token : '';
  const itemId = typeof params.itemId === 'string' ? params.itemId : '';

  const [item, setItem] = useState<ViewerItem | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchDetail() {
      if (!token || !itemId) return;
      setLoading(true);
      setError(null);
      try {
        // Try fetching schedule first, fallback to solicitation
        try {
          const schedItem = await api.getItemDetail(token, 'schedule', itemId);
          setItem(schedItem);
        } catch {
          const solicItem = await api.getItemDetail(token, 'solicitation', itemId);
          setItem(solicItem);
        }
      } catch (err: any) {
        setError(err.message || 'Failed to load item detail');
      } finally {
        setLoading(false);
      }
    }

    fetchDetail();
  }, [token, itemId]);

  if (loading) {
    return (
      <div className="max-w-3xl mx-auto py-6">
        <SkeletonLoader variant="detail" count={1} />
      </div>
    );
  }

  if (error || !item) {
    return (
      <div className="max-w-md mx-auto py-12 text-center space-y-4">
        <p className="text-sm text-red-600 dark:text-red-400 font-semibold">
          {error || 'Item not found.'}
        </p>
        <button
          type="button"
          onClick={() => router.push(`/${token}`)}
          className="px-4 py-2 rounded-xl text-xs font-bold text-white bg-[var(--color-seed)]"
        >
          Back to list
        </button>
      </div>
    );
  }

  return (
    <div className="py-4">
      <ItemDetail item={item} onBack={() => router.push(`/${token}`)} />
    </div>
  );
}

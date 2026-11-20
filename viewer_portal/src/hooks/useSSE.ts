'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { SSEUpdatePayload, ViewerItem } from '@/lib/types';
import { getApiBaseUrl } from '@/lib/api';

interface UseSSEOptions {
  token: string;
  enabled?: boolean;
  onUpdate?: (payload: SSEUpdatePayload) => void;
  onPollFallback?: () => void;
}

export function useSSE({ token, enabled = true, onUpdate, onPollFallback }: UseSSEOptions) {
  const [isConnected, setIsConnected] = useState(false);
  const [lastUpdatedTime, setLastUpdatedTime] = useState<Date | null>(null);
  const [isAnimating, setIsAnimating] = useState(false);

  const eventSourceRef = useRef<EventSource | null>(null);
  const retryTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const pollingIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const retryCountRef = useRef(0);

  const triggerUpdateAnimation = useCallback(() => {
    setLastUpdatedTime(new Date());
    setIsAnimating(true);
    setTimeout(() => {
      setIsAnimating(false);
    }, 3000);
  }, []);

  const connect = useCallback(() => {
    if (!enabled || !token || typeof window === 'undefined') return;

    if (eventSourceRef.current) {
      eventSourceRef.current.close();
    }

    const apiBaseUrl = getApiBaseUrl();
    const sseUrl = `${apiBaseUrl}/api/view/events/stream?token=${token}`;

    try {
      const es = new EventSource(sseUrl);
      eventSourceRef.current = es;

      es.onopen = () => {
        setIsConnected(true);
        retryCountRef.current = 0;
      };

      es.onmessage = (event) => {
        try {
          const payload: SSEUpdatePayload = JSON.parse(event.data);
          triggerUpdateAnimation();
          if (onUpdate) {
            onUpdate(payload);
          }
        } catch {
          // ignore parsing error
        }
      };

      es.onerror = () => {
        setIsConnected(false);
        es.close();
        eventSourceRef.current = null;

        // Exponential backoff reconnect
        const backoff = Math.min(1000 * Math.pow(2, retryCountRef.current), 30000);
        retryCountRef.current += 1;

        if (retryTimeoutRef.current) clearTimeout(retryTimeoutRef.current);
        retryTimeoutRef.current = setTimeout(() => {
          connect();
        }, backoff);
      };
    } catch {
      setIsConnected(false);
    }
  }, [enabled, token, onUpdate, triggerUpdateAnimation]);

  // Polling fallback (30s) especially for iOS Safari background/disconnects
  useEffect(() => {
    if (!enabled) return;

    pollingIntervalRef.current = setInterval(() => {
      if (!isConnected && onPollFallback) {
        onPollFallback();
        triggerUpdateAnimation();
      }
    }, 30000);

    return () => {
      if (pollingIntervalRef.current) clearInterval(pollingIntervalRef.current);
    };
  }, [enabled, isConnected, onPollFallback, triggerUpdateAnimation]);

  useEffect(() => {
    connect();

    return () => {
      if (eventSourceRef.current) {
        eventSourceRef.current.close();
      }
      if (retryTimeoutRef.current) {
        clearTimeout(retryTimeoutRef.current);
      }
    };
  }, [connect]);

  return {
    isConnected,
    lastUpdatedTime,
    isAnimating,
    reconnect: connect,
  };
}

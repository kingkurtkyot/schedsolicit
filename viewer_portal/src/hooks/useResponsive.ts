'use client';

import { useState, useEffect } from 'react';

export type Breakpoint = 'compact' | 'medium' | 'expanded';
export type Orientation = 'portrait' | 'landscape';

export function useResponsive() {
  const [breakpoint, setBreakpoint] = useState<Breakpoint>('compact');
  const [orientation, setOrientation] = useState<Orientation>('portrait');
  const [width, setWidth] = useState(0);
  const [height, setHeight] = useState(0);

  useEffect(() => {
    if (typeof window === 'undefined') return;

    const handleResize = () => {
      const w = window.innerWidth;
      const h = window.innerHeight;
      setWidth(w);
      setHeight(h);
      setOrientation(w > h ? 'landscape' : 'portrait');

      if (w < 600) {
        setBreakpoint('compact');
      } else if (w < 1024) {
        setBreakpoint('medium');
      } else {
        setBreakpoint('expanded');
      }
    };

    handleResize();
    window.addEventListener('resize', handleResize);
    window.addEventListener('orientationchange', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
      window.removeEventListener('orientationchange', handleResize);
    };
  }, []);

  return {
    breakpoint,
    orientation,
    width,
    height,
    isPhone: breakpoint === 'compact',
    isTablet: breakpoint === 'medium',
    isDesktop: breakpoint === 'expanded',
  };
}

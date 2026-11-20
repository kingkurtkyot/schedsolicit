import type { Config } from 'tailwindcss';

const config: Config = {
  darkMode: 'media',
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    screens: {
      compact: '0px',
      phone: '375px',
      tablet: '600px',
      medium: '600px',
      desktop: '1024px',
      expanded: '1440px',
    },
    extend: {
      colors: {
        brand: {
          seed: '#2E7D32',
          emerald: '#2E7D32',
          forest: '#1B5E20',
          mint: '#00C853',
          lime: '#64DD17',
        },
        surface: {
          light: '#F5F9F5',
          dark: '#1A2B1A',
          containerLight: '#EDF5ED',
          containerDark: '#243324',
          cardLight: '#FFFFFF',
          cardDark: '#203320',
          borderLight: '#D8E5D8',
          borderDark: '#2E442E',
        },
        priority: {
          low: '#66BB6A',
          medium: '#FFA726',
          high: '#EF5350',
          urgent: '#D50000',
        },
        status: {
          active: '#2196F3',
          done: '#4CAF50',
          cancelled: '#9E9E9E',
          pending: '#FF9800',
          approved: '#00C853',
          declined: '#F44336',
          given: '#7C4DFF',
          draft: '#78909C',
          sent: '#29B6F6',
          past: '#BDBDBD',
        },
        escalation: {
          safe: '#66BB6A',
          warning: '#FFA726',
          danger: '#EF5350',
        },
      },
      borderRadius: {
        xs: '4px',
        sm: '8px',
        md: '12px',
        lg: '16px',
        xl: '24px',
      },
      spacing: {
        safeTop: 'env(safe-area-inset-top, 0px)',
        safeBottom: 'env(safe-area-inset-bottom, 0px)',
        safeLeft: 'env(safe-area-inset-left, 0px)',
        safeRight: 'env(safe-area-inset-right, 0px)',
        touchTarget: '44px',
      },
      minHeight: {
        touch: '44px',
        dvh: '100dvh',
      },
      minWidth: {
        touch: '44px',
      },
      height: {
        dvh: '100dvh',
      },
      boxShadow: {
        elevationLow: '0 1px 3px rgba(27, 94, 32, 0.08), 0 1px 2px rgba(27, 94, 32, 0.04)',
        elevationMedium: '0 4px 6px -1px rgba(27, 94, 32, 0.1), 0 2px 4px -2px rgba(27, 94, 32, 0.06)',
        elevationHigh: '0 10px 15px -3px rgba(27, 94, 32, 0.12), 0 4px 6px -4px rgba(27, 94, 32, 0.08)',
      },
    },
  },
  plugins: [],
};

export default config;

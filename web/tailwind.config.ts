import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#F5F3F7',
          100: '#E8E2ED',
          200: '#D1C5DB',
          300: '#BAA8C9',
          400: '#A38BB7',
          500: '#897c98',
          600: '#6B3A8A',
          700: '#4a026f',
          800: '#3A0155',
          900: '#2A013F',
        },
        secondary: {
          100: '#E5E5E6',
          200: '#CACBCB',
          300: '#B0B1B2',
          400: '#959699',
          500: '#707173',
          600: '#5B5C5F',
          700: '#46474A',
        },
        success: '#10B981',
        error: '#EF4444',
        warning: '#F59E0B',
        info: '#3B82F6',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      borderRadius: {
        'xl': '1rem',
        '2xl': '1.5rem',
      },
    },
  },
  plugins: [],
}
export default config


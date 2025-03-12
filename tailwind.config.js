/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          200: '#bae6fd',
          300: '#7dd3fc',
          400: '#38bdf8',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
          800: '#075985',
          900: '#0c4a6e',
        },
        pdf: {
          500: '#E74C3C',
          600: '#C0392B',
        },
        image: {
          500: '#3498DB',
          600: '#2980B9',
        },
        text: {
          500: '#9B59B6',
          600: '#8E44AD',
        },
        calc: {
          500: '#2ECC71',
          600: '#27AE60',
        },
        file: {
          500: '#F39C12',
          600: '#E67E22',
        },
      },
      backdropBlur: {
        xs: '2px',
      },
    },
  },
  plugins: [],
};

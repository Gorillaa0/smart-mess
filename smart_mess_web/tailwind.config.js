/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#E8F5E9', 100: '#C8E6C9', 200: '#A5D6A7',
          300: '#81C784', 400: '#66BB6A', 500: '#4CAF50',
          600: '#43A047', 700: '#388E3C', 800: '#2E7D32', 900: '#1B5E20'
        },
        secondary: {
          50: '#FFF3E0', 100: '#FFE0B2', 500: '#FF9800', 700: '#F57C00', 900: '#E65100'
        },
        tertiary: {
          50: '#E3F2FD', 500: '#2196F3', 700: '#1976D2', 900: '#0D47A1'
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['Plus Jakarta Sans', 'Inter', 'sans-serif']
      }
    }
  },
  plugins: []
}

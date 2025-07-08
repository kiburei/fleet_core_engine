/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/views/**/*.html.erb",
    "./app/helpers/**/*.rb",
    "./app/assets/stylesheets/**/*.css",
    "./app/javascript/**/*.js"
  ],
  theme: {
    extend: {
colors: {
        primary: {
          50: '#fef2f2',
          100: '#fee2e2',
          200: '#fecaca',
          300: '#fca5a5',
          400: '#f87171',
          500: '#ef4444',
          600: '#bd0906',
          700: '#991b1b',
          800: '#7f1d1d',
          900: '#651515',
          950: '#450a0a',
        },
        secondary: {
          50: '#fafafa',
          100: '#f0f0f0',
          200: '#e0e0e0',
          300: '#c8c8c8',
          400: '#a8a8a8',
          500: '#989898',
          600: '#808080',
          700: '#676767',
          800: '#484848',
          900: '#373737',
          950: '#090909',
        }
      }
    },
  },
  plugins: [],
}

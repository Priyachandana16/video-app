/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "#0A0A0F",
        surface: "#12121A",
        surfaceLight: "#1A1A24",
        borderDark: "#262636",
        gold: {
          light: "#FFE082",
          DEFAULT: "#D4AF37",
          dark: "#AA820A"
        },
        crimson: {
          DEFAULT: "#800020",
          dark: "#4A0E17"
        }
      },
      fontFamily: {
        cinzel: ['"Cinzel"', 'serif'],
        playfair: ['"Playfair Display"', 'serif'],
        sans: ['"Plus Jakarta Sans"', 'sans-serif'],
      }
    },
  },
  plugins: [],
};


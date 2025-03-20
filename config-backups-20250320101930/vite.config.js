import { css } from "@vitejs/plugin-vue";
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [
  css({ postcss: true }),react()],
  server: {
    port: 3000,
    open: true,
    hmr: {
      overlay: false
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    minify: 'esbuild'
  }
});

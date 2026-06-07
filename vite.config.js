import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 9080;

export default defineConfig({
  plugins: [sveltekit()],
  server: {
    host: '0.0.0.0',
    port: PORT,
    strictPort: true,
    fs: {
      allow: ['..']
    },
    hmr: {
      overlay: false // Disable error overlay that can cause reconnects
    }
  },
  preview: {
    host: '0.0.0.0',
    port: PORT,
    strictPort: true
  },
  optimizeDeps: {
    exclude: ['systeminformation'] // Exclude server-side dependencies
  }
});

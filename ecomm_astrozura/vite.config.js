import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'
import process from 'node:process'

const forbiddenProductionValues = ["astrozura.cloud", "localhost", "127.0.0.1"];

function productionUrlGuard() {
  return {
    name: "astrozura-production-url-guard",
    config(_, { mode }) {
      if (mode !== "production") return;

      const env = loadEnv(mode, process.cwd(), "");
      const offenders = Object.entries(env)
        .filter(([key]) => key.startsWith("VITE_") || key.startsWith("FRONTEND_"))
        .filter(([, value = ""]) => forbiddenProductionValues.some((forbidden) => String(value).includes(forbidden)));

      if (offenders.length) {
        const details = offenders.map(([key, value]) => `${key}=${value}`).join(", ");
        throw new Error(`Unsafe production URL configuration detected: ${details}`);
      }
    },
  };
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [productionUrlGuard(), react()],
})

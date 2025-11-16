import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  output: 'standalone', // 支持 Docker 部署
  
  // 生产构建时忽略 ESLint 和 TypeScript 错误
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  
  env: {
    NEXT_PUBLIC_TRADING_MODE: process.env.TRADING_MODE || 'dry-run',
  },
};

export default nextConfig;

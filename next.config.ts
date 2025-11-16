import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  output: 'standalone', // 支持 Docker 部署
  env: {
    NEXT_PUBLIC_TRADING_MODE: process.env.TRADING_MODE || 'dry-run',
  },
};

export default nextConfig;

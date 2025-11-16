# 使用 Node.js 18 Debian 镜像（lightningcss 需要 glibc）
FROM node:18-slim AS base

# 安装依赖阶段
FROM base AS deps
RUN apt-get update && apt-get install -y \
    openssl ca-certificates \
    python3 make g++ gcc \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app

# 复制 package 文件
COPY package.json package-lock.json* ./

# 安装依赖并重新构建原生模块
RUN npm ci
RUN npm rebuild lightningcss --verbose

# 构建阶段
FROM base AS builder
WORKDIR /app

# 从 deps 阶段复制 node_modules
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# 生成 Prisma Client（在构建时生成）
RUN npx prisma generate

# 构建 Next.js 应用（不使用 turbopack 以避免兼容性问题）
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build:docker

# 生产运行阶段
FROM base AS runner
WORKDIR /app

# 设置环境变量
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# 创建非 root 用户
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# 复制必要的文件
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=builder /app/cron.ts ./cron.ts

# 安装生产环境所需的额外依赖（用于运行 cron.ts 和 Prisma）
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# 复制启动脚本
COPY docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

# 更改文件所有权
RUN chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# 使用启动脚本
ENTRYPOINT ["./docker-entrypoint.sh"]


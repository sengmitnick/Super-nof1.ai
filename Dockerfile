# 使用 Node.js 18 官方镜像（完整版，包含构建工具）
FROM node:18 AS base

# 启用 pnpm
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

# 安装依赖阶段
FROM base AS deps
WORKDIR /app

# 复制 package 文件和 prisma schema（postinstall 需要）
COPY package.json pnpm-lock.yaml .npmrc ./
COPY prisma ./prisma

# 使用 pnpm 安装依赖（会自动执行 postinstall: prisma generate）
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

# 构建阶段
FROM base AS builder
WORKDIR /app

# 从 deps 阶段复制 node_modules
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# 生成 Prisma Client（在构建时生成）
RUN pnpm exec prisma generate

# 构建 Next.js 应用（不使用 turbopack 以避免兼容性问题）
ENV NEXT_TELEMETRY_DISABLED=1
RUN pnpm run build:docker

# 生产运行阶段（使用 slim 减小镜像体积）
FROM node:18-slim AS runner
WORKDIR /app

# 安装运行时依赖
RUN apt-get update && apt-get install -y \
    openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 启用 pnpm（运行阶段也需要）
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

# 设置环境变量
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# 创建非 root 用户
RUN groupadd --system --gid 1001 nodejs
RUN useradd --system --uid 1001 -g nodejs nextjs

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


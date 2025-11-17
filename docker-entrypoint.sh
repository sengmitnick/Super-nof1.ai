#!/bin/bash
set -e

echo "🚀 Starting Super NOF1.ai..."

# 运行数据库迁移（生产环境使用 migrate deploy）
echo "🔄 Running database migrations..."
pnpm exec prisma migrate deploy

# 启动 Next.js 服务器（后台运行）
echo "🌐 Starting Next.js server..."
node server.js &
NEXTJS_PID=$!

# 等待 Next.js 服务器启动
echo "⏳ Waiting for Next.js server to start..."
sleep 5

# 启动 Cron 任务
echo "⏰ Starting Cron tasks..."
pnpm exec tsx cron.ts &
CRON_PID=$!

# 清理函数
cleanup() {
  echo "🛑 Shutting down..."
  kill $NEXTJS_PID $CRON_PID 2>/dev/null || true
  exit 0
}

# 捕获退出信号
trap cleanup SIGTERM SIGINT

echo "✅ All services started successfully!"
echo "🎮 Trading Mode: ${TRADING_MODE}"
echo "📊 Dashboard: ${NEXT_PUBLIC_URL}"

# 保持脚本运行
wait


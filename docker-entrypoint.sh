#!/bin/sh
set -e

echo "🚀 Starting Super NOF1.ai..."

# 等待数据库就绪
echo "⏳ Waiting for PostgreSQL..."
timeout=30
counter=0
until node -e "const { Client } = require('pg'); const client = new Client(process.env.DATABASE_URL); client.connect().then(() => { console.log('Connected'); client.end(); }).catch(() => process.exit(1));" 2>/dev/null || [ $counter -eq $timeout ]; do
  counter=$((counter + 1))
  echo "Waiting for database... ($counter/$timeout)"
  sleep 1
done

if [ $counter -eq $timeout ]; then
  echo "❌ Database connection timeout!"
  exit 1
fi

echo "✅ Database is ready!"

# 运行数据库迁移
echo "🔄 Running database migrations..."
npx prisma db push --skip-generate

# 启动 Next.js 服务器（后台运行）
echo "🌐 Starting Next.js server..."
node server.js &
NEXTJS_PID=$!

# 等待 Next.js 服务器启动
echo "⏳ Waiting for Next.js server to start..."
sleep 5

# 启动 Cron 任务
echo "⏰ Starting Cron tasks..."
node cron.ts &
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


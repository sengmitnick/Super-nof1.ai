#!/bin/sh
set -e

echo "🚀 Starting Super NOF1.ai..."

# 等待数据库就绪
echo "⏳ Waiting for PostgreSQL..."

# 从 DATABASE_URL 中提取数据库信息
DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
DB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')

echo "📡 Connecting to database at $DB_HOST:$DB_PORT..."

# 使用更长的超时和更好的重试逻辑
max_attempts=60
attempt=0

while [ $attempt -lt $max_attempts ]; do
  attempt=$((attempt + 1))
  
  # 使用 Prisma 尝试连接数据库
  if pnpm exec prisma db execute --stdin <<< "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ Database is ready!"
    break
  fi
  
  # 每 5 秒显示一次进度
  if [ $((attempt % 5)) -eq 0 ]; then
    echo "⏳ Still waiting for database... (attempt $attempt/$max_attempts)"
  fi
  
  # 最后一次尝试失败
  if [ $attempt -eq $max_attempts ]; then
    echo "❌ Database connection timeout after $max_attempts attempts!"
    echo "📋 DATABASE_URL: $DATABASE_URL"
    echo "🔍 Please check:"
    echo "   - Database container is running"
    echo "   - Network connectivity between containers"
    echo "   - DATABASE_URL is correctly formatted"
    exit 1
  fi
  
  sleep 1
done

# 运行数据库迁移
echo "🔄 Running database migrations..."
pnpm exec prisma db push --skip-generate

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


-- CreateEnum
CREATE TYPE "Opeartion" AS ENUM ('Buy', 'Sell', 'Hold');

-- CreateEnum
CREATE TYPE "Symbol" AS ENUM ('BTC', 'ETH', 'BNB', 'SOL', 'DOGE', 'ADA', 'DOT', 'MATIC', 'AVAX', 'LINK');

-- CreateEnum
CREATE TYPE "ModelType" AS ENUM ('Deepseek', 'DeepseekThinking', 'Qwen', 'Doubao');

-- CreateTable
CREATE TABLE "Metrics" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "model" "ModelType" NOT NULL,
    "metrics" JSONB[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Metrics_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Chat" (
    "id" TEXT NOT NULL,
    "model" "ModelType" NOT NULL DEFAULT 'Deepseek',
    "chat" TEXT NOT NULL DEFAULT '<no chat>',
    "reasoning" TEXT NOT NULL,
    "userPrompt" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Chat_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Trading" (
    "id" TEXT NOT NULL,
    "symbol" "Symbol" NOT NULL,
    "opeartion" "Opeartion" NOT NULL,
    "leverage" DOUBLE PRECISION,
    "amount" DOUBLE PRECISION,
    "pricing" DOUBLE PRECISION,
    "stopLoss" DOUBLE PRECISION,
    "takeProfit" DOUBLE PRECISION,
    "prediction" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "chatId" TEXT,

    CONSTRAINT "Trading_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TradingLesson" (
    "id" TEXT NOT NULL,
    "tradeId" TEXT NOT NULL,
    "symbol" "Symbol" NOT NULL,
    "decision" TEXT NOT NULL,
    "outcome" TEXT NOT NULL,
    "pnl" DOUBLE PRECISION NOT NULL,
    "pnlPercentage" DOUBLE PRECISION NOT NULL,
    "lessonText" TEXT NOT NULL,
    "exitReason" TEXT NOT NULL,
    "marketConditions" JSONB,
    "indicatorsAtEntry" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TradingLesson_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "TradingLesson_outcome_idx" ON "TradingLesson"("outcome");

-- CreateIndex
CREATE INDEX "TradingLesson_createdAt_idx" ON "TradingLesson"("createdAt");

-- CreateIndex
CREATE INDEX "TradingLesson_symbol_idx" ON "TradingLesson"("symbol");

-- AddForeignKey
ALTER TABLE "Trading" ADD CONSTRAINT "Trading_chatId_fkey" FOREIGN KEY ("chatId") REFERENCES "Chat"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TradingLesson" ADD CONSTRAINT "TradingLesson_tradeId_fkey" FOREIGN KEY ("tradeId") REFERENCES "Trading"("id") ON DELETE CASCADE ON UPDATE CASCADE;


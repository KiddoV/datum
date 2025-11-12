-- =====================================================
-- COMPLETE PAINT MANAGEMENT SYSTEM SETUP
-- =====================================================
-- Run this script in your Supabase SQL editor to set up
-- the complete painting management system from scratch.

-- =====================================================
-- 1. CREATE PAINT_STROKES TABLE (if not exists)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.paint_strokes (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    canvas_id TEXT NOT NULL DEFAULT '',
    points JSONB NOT NULL,
    color BIGINT NOT NULL,
    stroke_width REAL NOT NULL,
    "order" INTEGER NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    modified_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for paint_strokes
ALTER TABLE public.paint_strokes ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for paint_strokes
DROP POLICY IF EXISTS "Users can only access their own paint strokes" ON public.paint_strokes;
CREATE POLICY "Users can only access their own paint strokes" ON public.paint_strokes
    FOR ALL USING (auth.uid()::text = user_id);

-- Create indexes for paint_strokes
CREATE INDEX IF NOT EXISTS idx_paint_strokes_user_id ON public.paint_strokes(user_id);
CREATE INDEX IF NOT EXISTS idx_paint_strokes_canvas_id ON public.paint_strokes(canvas_id);
CREATE INDEX IF NOT EXISTS idx_paint_strokes_modified_at ON public.paint_strokes(modified_at);
CREATE INDEX IF NOT EXISTS idx_paint_strokes_order ON public.paint_strokes("order");

-- Enable realtime for paint_strokes
ALTER PUBLICATION supabase_realtime ADD TABLE public.paint_strokes;

-- =====================================================
-- 2. CREATE PAINT_CANVASES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.paint_canvases (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    thumbnail_stroke_data JSONB,
    stroke_count INTEGER DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    modified_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for paint_canvases
ALTER TABLE public.paint_canvases ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for paint_canvases
DROP POLICY IF EXISTS "Users can only access their own paint canvases" ON public.paint_canvases;
CREATE POLICY "Users can only access their own paint canvases" ON public.paint_canvases
    FOR ALL USING (auth.uid()::text = user_id);

-- Create indexes for paint_canvases
CREATE INDEX IF NOT EXISTS idx_paint_canvases_user_id ON public.paint_canvases(user_id);
CREATE INDEX IF NOT EXISTS idx_paint_canvases_modified_at ON public.paint_canvases(modified_at);

-- Enable realtime for paint_canvases
ALTER PUBLICATION supabase_realtime ADD TABLE public.paint_canvases;

-- =====================================================
-- SETUP COMPLETE - Run verification below
-- =====================================================

-- Verification query (run this separately to check setup):
/*
SELECT
    'paint_canvases' as table_name,
    COUNT(*) as record_count
FROM public.paint_canvases
UNION ALL
SELECT
    'paint_strokes' as table_name,
    COUNT(*) as record_count
FROM public.paint_strokes;
*/

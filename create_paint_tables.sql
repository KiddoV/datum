-- =====================================================
-- PAINT MANAGEMENT SYSTEM - SUPABASE SCHEMA
-- =====================================================
-- This file contains all the SQL queries needed to set up
-- the new painting management system with canvases and strokes.

-- =====================================================
-- 1. CREATE PAINT_CANVASES TABLE
-- =====================================================

-- Create the paint_canvases table
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

-- Enable Row Level Security
ALTER TABLE public.paint_canvases ENABLE ROW LEVEL SECURITY;

-- Create RLS policy - Users can only access their own paint canvases
DROP POLICY IF EXISTS "Users can only access their own paint canvases" ON public.paint_canvases;
CREATE POLICY "Users can only access their own paint canvases" ON public.paint_canvases
    FOR ALL USING (auth.uid()::text = user_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_paint_canvases_user_id ON public.paint_canvases(user_id);
CREATE INDEX IF NOT EXISTS idx_paint_canvases_modified_at ON public.paint_canvases(modified_at);

-- Enable realtime for this table
ALTER PUBLICATION supabase_realtime ADD TABLE public.paint_canvases;

-- =====================================================
-- 2. CREATE/UPDATE PAINT_STROKES TABLE
-- =====================================================

-- Create paint_strokes table if it doesn't exist (with canvas_id included)
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
-- 3. MIGRATION FOR EXISTING DATA (OPTIONAL)
-- =====================================================

-- Create default canvases for existing strokes (run this only if you have existing data)
-- Uncomment and modify as needed for your migration strategy

/*
-- Insert default canvases for users with existing strokes
INSERT INTO public.paint_canvases (id, user_id, title, description, stroke_count, created_at, modified_at)
SELECT
    'default-canvas-' || ps.user_id as id,
    ps.user_id,
    'My Paintings' as title,
    'Default canvas for existing strokes' as description,
    COUNT(*) as stroke_count,
    MIN(ps.created_at) as created_at,
    MAX(ps.modified_at) as modified_at
FROM public.paint_strokes ps
WHERE ps.canvas_id = '' OR ps.canvas_id IS NULL
GROUP BY ps.user_id
ON CONFLICT (id) DO NOTHING;

-- Update existing strokes to use the default canvas
UPDATE public.paint_strokes
SET canvas_id = 'default-canvas-' || user_id
WHERE canvas_id = '' OR canvas_id IS NULL;
*/

-- =====================================================
-- 4. VERIFICATION QUERIES
-- =====================================================

-- Check if tables were created successfully
SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('paint_canvases', 'paint_strokes')
ORDER BY tablename;

-- Check if RLS is enabled
SELECT
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('paint_canvases', 'paint_strokes')
ORDER BY tablename;

-- Check policies
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('paint_canvases', 'paint_strokes')
ORDER BY tablename, policyname;

-- Check indexes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('paint_canvases', 'paint_strokes')
ORDER BY tablename, indexname;

-- =====================================================
-- 5. TEST DATA (OPTIONAL - for development)
-- =====================================================

-- Insert test canvas (uncomment to add test data)
/*
INSERT INTO public.paint_canvases (id, user_id, title, description, stroke_count, created_at, modified_at)
VALUES (
    'test-canvas-123',
    'test-user-456',
    'Test Painting',
    'A test painting canvas',
    0,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;
*/

-- =====================================================
-- SETUP COMPLETE
-- =====================================================

-- Run this query to verify everything is set up correctly:
/*
SELECT
    'Tables created:' as status,
    COUNT(*) as count
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('paint_canvases', 'paint_strokes');
*/

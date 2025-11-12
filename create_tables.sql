-- PAINT FEATURE TABLES FOR SUPABASE
-- Copy and paste this entire script into your Supabase SQL editor

-- =============================================================================
-- STEP 1: CREATE SYNC_METADATA TABLE
-- =============================================================================

DROP TABLE IF EXISTS public.sync_metadata;

CREATE TABLE public.sync_metadata (
    user_id TEXT PRIMARY KEY,
    last_sync_time TEXT NULL,
    last_successful_sync_time TEXT NULL,
    data_hash TEXT NULL,
    device_id TEXT NULL,
    devices TEXT NULL,
    custom_metadata JSONB NULL,
    entity_counts JSONB NULL,
    sync_status TEXT NOT NULL DEFAULT 'pending',
    sync_version INTEGER NOT NULL DEFAULT 0,
    server_timestamp TEXT NULL,
    conflict_count INTEGER NOT NULL DEFAULT 0,
    error_message TEXT NULL,
    retry_count INTEGER NOT NULL DEFAULT 0,
    sync_duration INTEGER NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.sync_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own sync metadata" ON public.sync_metadata
    FOR ALL USING (auth.uid()::text = user_id);

CREATE INDEX idx_sync_metadata_user_id ON public.sync_metadata(user_id);
CREATE INDEX idx_sync_metadata_sync_status ON public.sync_metadata(sync_status);

-- =============================================================================
-- STEP 2: CREATE PAINT_STROKES TABLE
-- =============================================================================

DROP TABLE IF EXISTS public.paint_strokes;

CREATE TABLE public.paint_strokes (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    points JSONB NOT NULL,
    color BIGINT NOT NULL,
    stroke_width REAL NOT NULL,
    "order" INTEGER NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    modified_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.paint_strokes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own paint strokes" ON public.paint_strokes
    FOR ALL USING (auth.uid()::text = user_id);

CREATE INDEX idx_paint_strokes_user_id ON public.paint_strokes(user_id);
CREATE INDEX idx_paint_strokes_modified_at ON public.paint_strokes(modified_at);
CREATE INDEX idx_paint_strokes_order ON public.paint_strokes("order");

ALTER PUBLICATION supabase_realtime ADD TABLE public.paint_strokes;

-- =============================================================================
-- STEP 3: TEST THE TABLES (Optional - run after creating)
-- =============================================================================

-- Test sync_metadata table
-- INSERT INTO public.sync_metadata (user_id, sync_status) VALUES ('test-user', 'pending');

-- Test paint_strokes table
-- INSERT INTO public.paint_strokes (id, user_id, points, color, stroke_width, "order")
-- VALUES ('test-stroke-123', 'test-user', '[{"x": 100.0, "y": 200.0}, {"x": 150.0, "y": 250.0}]', 4294198070, 5.0, 1);

-- =============================================================================
-- FIX: Rename pain_Stores to paint_strokes (if you created it with wrong name)
-- =============================================================================

-- If you created the table with wrong name, run these commands:
ALTER TABLE public.pain_Stores RENAME TO paint_strokes;
ALTER INDEX idx_pain_Stores_user_id RENAME TO idx_paint_strokes_user_id;
ALTER INDEX idx_pain_Stores_modified_at RENAME TO idx_paint_strokes_modified_at;
ALTER INDEX idx_pain_Stores_order RENAME TO idx_paint_strokes_order;

-- =============================================================================
-- VERIFY TABLES EXIST
-- =============================================================================

-- Check if tables exist
SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('sync_metadata', 'paint_strokes');

-- Check table structure for paint_strokes
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'paint_strokes'
ORDER BY ordinal_position;

-- =============================================================================
-- TEST TABLE ACCESS (run these after creating tables)
-- =============================================================================

-- Test 1: Check if you can select from paint_strokes
-- SELECT * FROM public.paint_strokes LIMIT 1;

-- Test 2: Try to insert a test record
-- INSERT INTO public.paint_strokes (id, user_id, points, color, stroke_width, "order")
-- VALUES ('test-123', 'your-user-id-here', '[{"x": 100.0, "y": 200.0}]', 4294198070, 5.0, 1);

-- Test 3: Check current user
-- SELECT auth.uid();

-- =============================================================================
-- CHECK RLS POLICIES
-- =============================================================================

-- Check RLS policies
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
AND tablename IN ('sync_metadata', 'paint_strokes');

-- Check if RLS is enabled
SELECT
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('sync_metadata', 'paint_strokes');

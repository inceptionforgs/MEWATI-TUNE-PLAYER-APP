-- Likes table + RLS policies for Mewati Tune Player

-- 1. Add like_count column to songs table
ALTER TABLE songs ADD COLUMN IF NOT EXISTS like_count INTEGER DEFAULT 0;

-- 2. Create likes table (track user likes)
CREATE TABLE IF NOT EXISTS likes (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  song_id UUID REFERENCES songs(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, song_id)
);

-- 3. Enable Row Level Security
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for likes
CREATE POLICY "Users can view all likes" ON likes
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own likes" ON likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own likes" ON likes
  FOR DELETE USING (auth.uid() = user_id);

-- 5. Function to increment like count atomically
CREATE OR REPLACE FUNCTION increment_like_count(song_id_input UUID)
RETURNS void AS $$
  UPDATE songs SET like_count = like_count + 1 WHERE id = song_id_input;
$$ LANGUAGE sql;

-- 6. Function to decrement like count atomically
CREATE OR REPLACE FUNCTION decrement_like_count(song_id_input UUID)
RETURNS void AS $$
  UPDATE songs SET like_count = GREATEST(like_count - 1, 0) WHERE id = song_id_input;
$$ LANGUAGE sql;
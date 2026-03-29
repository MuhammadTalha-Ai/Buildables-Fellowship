-- db_schema.sql
CREATE TABLE IF NOT EXISTS events_clean (
  event_id TEXT PRIMARY KEY,
  user_id TEXT,
  game_id TEXT,
  platform TEXT,
  event_time TIMESTAMP WITH TIME ZONE,
  event_type TEXT,
  play_time_seconds DOUBLE PRECISION,
  raw_payload JSONB
);

CREATE TABLE IF NOT EXISTS hourly_metrics (
  game_id TEXT,
  hour_start TIMESTAMP WITH TIME ZONE,
  concurrent_players INTEGER,
  total_play_time_seconds DOUBLE PRECISION,
  PRIMARY KEY (game_id, hour_start)
);

CREATE TABLE IF NOT EXISTS malformed_events (
  id SERIAL PRIMARY KEY,
  source_file TEXT,
  line_number BIGINT,
  raw_line TEXT,
  error_reason TEXT,
  detected_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

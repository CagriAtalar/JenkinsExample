-- Counter tablosunu oluştur
CREATE TABLE IF NOT EXISTS counter (
    id INTEGER PRIMARY KEY,
    count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- İlk kaydı ekle
INSERT INTO counter (id, count) VALUES (1, 0) 
ON CONFLICT (id) DO NOTHING;

-- Updated_at alanını otomatik güncelleyen trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_counter_updated_at 
    BEFORE UPDATE ON counter 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

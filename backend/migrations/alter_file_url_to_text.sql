-- Migration: Alter file_url column to TEXT to support base64 data URLs
-- Base64 data URLs can be very long (millions of characters for large files)

ALTER TABLE messages ALTER COLUMN file_url TYPE TEXT;



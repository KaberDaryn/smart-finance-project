CREATE TABLE IF NOT EXISTS merchant_categories (
    user_id BIGINT NOT NULL REFERENCES users(id),
    merchant_key TEXT NOT NULL,
    category TEXT NOT NULL,
    PRIMARY KEY (user_id, merchant_key)
)

-- STEP 1: TABLE CREATION

CREATE TABLE dim_ps5_games (
    game_sk SERIAL PRIMARY KEY,       -- Surrogate Key
    game_id INT NOT NULL,             -- Business Key
    title VARCHAR(255),
    genre VARCHAR(100),
    developer VARCHAR(100),
    price NUMERIC(10,2),
    ps_plus_included BOOLEAN,
    row_hash TEXT,                    -- MD5 hash of attribute columns
    start_date TIMESTAMP NOT NULL DEFAULT NOW(),
    end_date TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE stg_ps5_games (
    game_id INT NOT NULL,
    title VARCHAR(255),
    genre VARCHAR(100),
    developer VARCHAR(100),
    price NUMERIC(10,2),
    ps_plus_included BOOLEAN,
    row_hash TEXT
);


-- STEP 2: INITIAL DATA INSERT

INSERT INTO dim_ps5_games (game_id, title, genre, developer, price, ps_plus_included, row_hash, start_date)
VALUES
(1, 'Spider-Man 2', 'Action', 'Insomniac Games', 69.99, TRUE, md5('Action|Insomniac Games|69.99|1'), NOW()),
(2, 'Demon''s Souls', 'RPG', 'Bluepoint Games', 59.99, FALSE, md5('RPG|Bluepoint Games|59.99|0'), NOW());



-- STEP 3: STAGING DATA INSERT

INSERT INTO stg_ps5_games (game_id, title, genre, developer, price, ps_plus_included, row_hash)
VALUES
-- Changed row: Spider-Man 2 price reduced
(1, 'Spider-Man 2', 'Action', 'Insomniac Games', 49.99, TRUE, md5('Action|Insomniac Games|49.99|1')),

-- Changed row: Demon’s Souls added to PS Plus
(2, 'Demon''s Souls', 'RPG', 'Bluepoint Games', 59.99, TRUE, md5('RPG|Bluepoint Games|59.99|1')),

-- Unchanged row: Spider-Man 2 DLC (unchanged title/genre/developer/price/psplus)
(3, 'Spider-Man 2 DLC', 'Action', 'Insomniac Games', 19.99, FALSE, md5('Action|Insomniac Games|19.99|0')),

-- New row: Final Fantasy XVI (completely new game_id)
(4, 'Final Fantasy XVI', 'RPG', 'Square Enix', 69.99, FALSE, md5('RPG|Square Enix|69.99|0'));
 


-- STEP 4: SCD-2 IMPLEMENTATION

WITH compare AS (
    SELECT 
        s.game_id,
        s.title,
        s.genre,
        s.developer,
        s.price,
        s.ps_plus_included,
        s.row_hash,
        d.game_sk,
        d.row_hash AS existing_hash
    FROM stg_ps5_games s
    LEFT JOIN dim_ps5_games d
    ON s.game_id = d.game_id AND d.is_active = TRUE
)
   
-- 1. Expire old records where hash differs

UPDATE dim_ps5_games d
SET end_date = NOW(),
    is_active = FALSE
FROM compare c
WHERE d.game_sk = c.game_sk
  AND c.existing_hash IS NOT NULL
  AND c.row_hash <> c.existing_hash;


-- 2. Insert new or changed records
INSERT INTO dim_ps5_games (game_id, title, genre, developer, price, ps_plus_included, row_hash, start_date)
SELECT c.game_id, c.title, c.genre, c.developer, c.price, c.ps_plus_included, c.row_hash, NOW()
FROM compare c
WHERE c.existing_hash IS NULL   -- New game
   OR c.row_hash <> c.existing_hash; -- Changed game


-- STEP 5: BEFORE / AFTER QUERIES


-- Before applying SCD2

--SELECT * FROM dim_ps5_games ORDER BY game_id, start_date;

-- Staging data

--SELECT * FROM stg_ps5_games;

-- After applying SCD2

--SELECT * FROM dim_ps5_games ORDER BY game_id, start_date;

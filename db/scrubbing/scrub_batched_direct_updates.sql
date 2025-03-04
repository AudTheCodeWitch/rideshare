/*
 * BATCH EMAIL SCRUBBING PROCEDURE
 * ==============================
 * 
 * This procedure performs email anonymization in batches to handle large datasets
 * efficiently while avoiding timeout and memory issues.
 *
 * PROCEDURE SIGNATURE:
 *   SCRUB_BATCHES() → void
 *
 * ALGORITHM OVERVIEW:
 * 1. Determines the range of user IDs to process
 * 2. Processes users in batches of 1000
 * 3. Commits after each batch to prevent transaction bloat
 * 4. Provides progress feedback via RAISE NOTICE
 *
 * KEY FEATURES:
 * 1. Memory efficient (processes fixed-size batches)
 * 2. Transaction safe (commits per batch)
 * 3. Progress monitoring
 * 4. Resumable (can be restarted if interrupted)
 */

CREATE OR REPLACE PROCEDURE SCRUB_BATCHES()
LANGUAGE PLPGSQL                                    -- Use PL/pgSQL for procedural capabilities
AS $$
DECLARE
    -- Initialize variables for batch processing
    current_id INT := (SELECT MIN(id) FROM users);  -- Start with the lowest user ID
    max_id INT := (SELECT MAX(id) FROM users);      -- End with the highest user ID
    batch_size INT := 1000;                        -- Process 1000 records at a time
    rows_updated INT;                              -- Track number of rows updated per batch
BEGIN
    -- Process records in batches until we reach the maximum ID
    WHILE current_id <= max_id LOOP
        -- Update a batch of records:
        -- 1. Target users within the current ID range
        -- 2. Apply email scrubbing function to each record
        -- 3. Use half-open interval [current_id, current_id + batch_size)
        UPDATE users
        SET email = SCRUB_EMAIL(email)             -- Apply anonymization to each email
        WHERE id >= current_id                      -- Lower bound of current batch
        AND id < current_id + batch_size;          -- Upper bound (exclusive)

        -- Capture the number of rows actually updated
        -- (might be less than batch_size if there are gaps in IDs)
        GET DIAGNOSTICS rows_updated = ROW_COUNT;

        -- Commit the current batch to:
        -- 1. Release memory
        -- 2. Free locks
        -- 3. Make changes permanent
        COMMIT;

        -- Log progress for monitoring and debugging
        RAISE NOTICE 'current_id: % - Number of rows updated: %',
        current_id, rows_updated;

        -- Advance to next batch
        -- Add 1 to avoid processing the last ID twice
        current_id := current_id + batch_size + 1;
    END LOOP;
END;
$$;

/*
 * USAGE NOTES:
 * - Processes approximately 1000 records per transaction
 * - Progress can be monitored in the database logs
 * - Safe to run multiple times (idempotent)
 * - Can be interrupted and resumed without data loss
 *
 * EXAMPLE USAGE:
 *   CALL SCRUB_BATCHES();
 */

-- Execute the procedure
CALL SCRUB_BATCHES();

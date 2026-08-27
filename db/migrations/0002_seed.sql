-- Forward-only migration 0002: reference data so a new environment is not empty.
-- Re-runnable: each row is inserted only when its title is absent.
INSERT INTO compliance (title, reference, status, priority)
SELECT 'Sample Compliance 1', 'C-0001', 'new', 'low'
WHERE NOT EXISTS (SELECT 1 FROM compliance WHERE title = 'Sample Compliance 1');
INSERT INTO compliance (title, reference, status, priority)
SELECT 'Sample Compliance 2', 'C-0002', 'in-progress', 'normal'
WHERE NOT EXISTS (SELECT 1 FROM compliance WHERE title = 'Sample Compliance 2');
INSERT INTO compliance (title, reference, status, priority)
SELECT 'Sample Compliance 3', 'C-0003', 'complete', 'high'
WHERE NOT EXISTS (SELECT 1 FROM compliance WHERE title = 'Sample Compliance 3');
INSERT INTO compliance (title, reference, status, priority)
SELECT 'Sample Compliance 4', 'C-0004', 'new', 'low'
WHERE NOT EXISTS (SELECT 1 FROM compliance WHERE title = 'Sample Compliance 4');

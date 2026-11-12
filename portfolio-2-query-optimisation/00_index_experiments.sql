-- =====================================================================
-- Portfolio 2 – Step 0: Index experiments (sequential scan vs index scan)
--
-- A small, early test on 10,000 practice students to see how PostgreSQL
-- searches a table with and without an index.
--
-- IMPORTANT: run this only on EMPTY tables (straight after schema.sql),
-- or in a separate test database. It inserts practice data that clashes
-- with 01_seed_data.sql. Run schema.sql again afterwards to reset.
-- =====================================================================

-- ---------- 1. Minimum structure a student needs ----------
INSERT INTO faculty (name) VALUES ('Faculty of Science');
INSERT INTO department (name, faculty_id) VALUES ('Computer Science', 1);
INSERT INTO programme (name, dept_id, duration_years) VALUES ('B.Sc. Computer Science', 1, 4);

-- ---------- 2. 10,000 practice students ----------
-- generate_series(1, 10000) produces one row per number (n).
-- Surnames cycle through 5 names, so each surname matches 2,000 students.
INSERT INTO student (matric_no, first_name, last_name, email, programme_id, entry_year, current_level)
SELECT
  'LMU/2024/' || lpad(n::text, 5, '0'),
  'Student' || n,
  (ARRAY['Adeyemi','Okafor','Bello','Eze','Lawal'])[1 + n % 5],
  'student' || n || '@lmu.edu.ng',
  1, 2024, 200
FROM generate_series(1, 10000) AS n;

-- Refresh statistics so PostgreSQL knows the table's size and contents
ANALYZE student;

-- Check the data
SELECT count(*) FROM student;
SELECT * FROM student LIMIT 5;


-- =====================================================================
-- Experiment 1: a column that already has an index
-- matric_no is UNIQUE, so PostgreSQL created an index automatically.
-- Result: Index Scan
-- =====================================================================
EXPLAIN ANALYZE
SELECT * FROM student WHERE matric_no = 'LMU/2024/05000';


-- =====================================================================
-- Experiment A: a search matching ONE row (high selectivity)
-- =====================================================================

-- A1. Before the index – Result: Seq Scan, 9,999 rows removed, 127 pages read
EXPLAIN ANALYZE
SELECT * FROM student WHERE first_name = 'Student5000';

-- Create the index
CREATE INDEX idx_student_first_name ON student (first_name);

-- A2. After the index – Result: Index Scan, 3 pages read
EXPLAIN ANALYZE
SELECT * FROM student WHERE first_name = 'Student5000';


-- =====================================================================
-- Experiment B: a search matching MANY rows (low selectivity)
-- 'Bello' matches 2,000 of 10,000 students (20%), spread across every page.
-- =====================================================================

-- B1. Before the index – Result: Seq Scan, 8,000 rows removed, 127 pages read
EXPLAIN ANALYZE
SELECT * FROM student WHERE last_name = 'Bello';

-- Create the index
CREATE INDEX idx_student_last_name ON student (last_name);

-- B2. After the index – Result: Bitmap Heap Scan, 131 pages read
-- Only a small gain: every page holds a Bello, so all pages are still read.
EXPLAIN ANALYZE
SELECT * FROM student WHERE last_name = 'Bello';


-- =====================================================================
-- Recorded results
--
-- | Search                    | Without index         | With index                  | Pages read |
-- |---------------------------|-----------------------|-----------------------------|------------|
-- | One student by first name | 2.843 ms (Seq Scan)   | 0.060 ms (Index Scan)       | 127 -> 3   |
-- | 2,000 students by surname | 1.380 ms (Seq Scan)   | 0.951 ms (Bitmap Heap Scan) | 127 -> 131 |
--
-- Conclusion: indexes help most for selective queries that return a small
-- fraction of a table. When matching rows are spread across every page,
-- the database still has to read all pages, so the index gives little benefit.
-- =====================================================================


-- ---------- Clean up ----------
-- These practice indexes are not part of the final design.
DROP INDEX IF EXISTS idx_student_first_name;
DROP INDEX IF EXISTS idx_student_last_name;
-- Then run schema.sql to remove the practice data before 01_seed_data.sql.

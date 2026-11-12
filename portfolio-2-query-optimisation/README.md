# Portfolio 2: Query Processing and Optimisation

**Case study:** Lagos Metropolitan University (LMU) Student Result Portal
**Database:** PostgreSQL

## What this portfolio covers

This folder loads a realistic volume of data into the Portfolio 1 schema, runs four business queries, examines their execution plans with `EXPLAIN ANALYZE`, and tests two optimisation techniques: indexes and a materialized view. It records where each technique helped, where it did not, and why.

## Files in this folder

| File | Purpose |
|---|---|
| `00_index_experiments.sql` | Early experiments comparing sequential and index scans on the student table |
| `01_seed_data.sql` | Generates the test university: 10,000 students, 300,010 registrations, 296,995 results |
| `02_queries.sql` | Grade view plus four business queries, each with `EXPLAIN ANALYZE` |
| `03_indexes.sql` | Two indexes added after measuring the "before" plans |
| `04_materialized_view.sql` | Pre-computed reporting table for the slowest query |
| `screenshots/` | Row counts, execution plans and timings |

## How to run

In the pgAdmin Query Tool on the `lmu_result_portal` database:

1. `../portfolio-1-database-design/schema.sql` (resets to empty tables)
2. `01_seed_data.sql`
3. `02_queries.sql` (before indexes: record plans and times)
4. `03_indexes.sql`
5. `02_queries.sql` again (after indexes: record plans and times)
6. `04_materialized_view.sql`

Each query was run with `EXPLAIN ANALYZE` at least twice, and the second Execution Time was recorded, because the first run is slower while data is loaded into memory.

## Dataset

| Table | Rows |
|---|---|
| faculty | 5 |
| department | 20 |
| programme | 20 |
| lecturer | 200 |
| course | 800 |
| academic_session | 6 (2020/2021 to 2025/2026) |
| course_offering | 4,800 |
| student | 10,000 |
| registration | 300,010 |
| result | 296,995 |

Data was generated with `generate_series`, `CROSS JOIN` and `random()`.

- Each student registers only for courses in their own department, at the level matching their year of study, for each session from their entry year until 400 level.
- About 1% of registrations are dropped and have no result.
- Results follow the real cycle: past sessions are published; in the current session, semester 1 is approved and semester 2 is still in draft with no exam score.
- `setseed(0.42)` makes the random values repeatable, so the same dataset can be rebuilt for fair before/after comparisons.

## The queries

`v_result_grade` is a view that joins each result to `grade_scale` to derive the total, grade and grade point. Grades are never stored (see the Portfolio 1 normalisation), so the view calculates them from current scores every time. A LEFT JOIN keeps draft results whose total is still blank.

| Query | Business purpose | SQL features |
|---|---|---|
| Q1 | Transcript for one student | 5-table join through a view, range join to grade_scale |
| Q2 | Result sheet for one course offering | Join starting from the course side |
| Q3 | Top 10 students by CGPA in a programme | GROUP BY, weighted average, window function `RANK()`, subquery |
| Q4 | Pass rate per faculty for one session | Aggregation over ~66,000 results, `count(*) FILTER` |

## Indexes added

PostgreSQL automatically indexes primary keys and UNIQUE columns, but not foreign keys.

| Index | Column | Reason |
|---|---|---|
| `idx_registration_offering` | registration(offering_id) | The existing unique index is on (student_id, offering_id). A multi-column index works best when the search uses its first column, so it suits "all registrations for one student" (Q1) but not "all students in one offering" (Q2). |
| `idx_student_programme` | student(programme_id) | Q3 finds all students in one programme. |

## Results

| Query | Before (ms) | After indexes (ms) | Plan change |
|---|---|---|---|
| Q1 Transcript | 5.884 | 2.261 | None. Already used the matric_no index and the (student_id, offering_id) index |
| Q2 Course result sheet | 42.721 | 2.879 | Now uses `idx_registration_offering` to go directly to the offering's ~100 registrations |
| Q3 Top 10 CGPA | 571.433 | 398.458 | Student lookup uses `idx_student_programme`; registration still read by sequential scan |
| Q4 Pass rate per faculty | 591.853 | 755.612 | None. Sequential scans on result and registration |
| Q4 with materialized view | – | 258.123 | Reads one pre-joined table |

## Performance analysis

**Where an index worked (Q2).** The result sheet query searches registrations by offering. Because the existing composite index begins with student_id, it could not locate one offering's registrations directly. A dedicated index on `offering_id` lets PostgreSQL jump to the matching rows, making the query about 15 times faster. The plan confirms the new index is used.

**Where an index already existed (Q1).** The transcript query was already efficient, because `matric_no` is UNIQUE and the composite registration index begins with student_id. The Portfolio 1 constraints therefore also supported performance. Its faster "after" time is not due to an index, since the plan was unchanged; it reflects data already being cached in memory.

**Where an index had limited effect (Q3).** The new index speeds up finding the programme's students, but those students have about 15,000 registrations between them. When a query needs a large share of a table, one sequential pass is cheaper than thousands of individual index lookups, so PostgreSQL correctly continues to scan the registration table. This shows that an index's value depends on selectivity: it helps most when a query returns a small fraction of the rows.

**Where indexes could not help (Q4).** Q4 aggregates a whole session's results and matches every score to a grade range. No index removes that work. Its slower "after" time came from normal variation between runs, since nothing it uses had changed. A single timing is therefore not reliable evidence on its own; the execution plan explains whether a change was caused by an optimisation.

**A different technique (materialized view).** `mv_result_summary` performs the joins once and stores the result as a table, so the report reads one indexed table instead of joining six. This made Q4 about 2.3 times faster than the original. It is a controlled denormalisation: the stored copy does not update automatically and must be refreshed with `REFRESH MATERIALIZED VIEW CONCURRENTLY` after results change. `CONCURRENTLY` lets users keep reading the old copy during the refresh, which matters on result-release day. This is acceptable for faculty reports produced after publication, but not for a student viewing a live result, which should always use the normalised tables.

**Cost of indexes.** Every index must also be updated whenever rows are inserted or changed, which slows writes slightly and uses extra storage. For a result portal this trade-off is acceptable: scores are written in bursts once per semester but read constantly.

## Lessons from the early experiments

Before building the full dataset, a simple test on 10,000 students showed the core idea:

| Search | Without index | With index | Pages read |
|---|---|---|---|
| One student by first name | 2.843 ms (Seq Scan) | 0.060 ms (Index Scan) | 127 → 3 |
| 2,000 students by surname | 1.380 ms (Seq Scan) | 0.951 ms (Bitmap Heap Scan) | 127 → 131 |

The surname index gave little benefit because matching students were spread across every page of the table, so PostgreSQL still had to read them all.

## Screenshots

| Evidence | File |
|---|---|
| Index experiments | `screenshots/lesson1-*.png` |
| Row counts after loading data | `screenshots/01-row-counts.png` |
| Q1–Q4 plans before indexes | `screenshots/02-before-q*.png` |
| List of indexes | `screenshots/03-indexes.png` |
| Q1–Q4 plans after indexes | `screenshots/04-after-q*.png` |
| Q4 with materialized view | `screenshots/05-q4-materialized-view.png` |

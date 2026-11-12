# Portfolio 3: Transactions and Concurrency

**Case study:** Lagos Metropolitan University (LMU) Student Result Portal
**Database:** PostgreSQL (default isolation level: READ COMMITTED)

## What this portfolio covers

This folder demonstrates how the result portal keeps data correct when a change fails partway through, and when two users change the same data at the same time. It covers committing and rolling back transactions, automatic rollback when a rule is broken, a race condition that overbooks a course, and how row locking prevents it.

## Files in this folder

| File | Purpose |
|---|---|
| `01_commit_rollback.sql` | Setup, Experiment 1 (COMMIT), Experiment 2a (manual ROLLBACK), Experiment 2b (automatic rollback) |
| `02_concurrency.sql` | Experiment 3: two sessions registering for the last seat, without and with locking |
| `screenshots/` | Evidence for each experiment |

## Key concepts

A **transaction** is a group of statements that succeed or fail as one unit. It starts with `BEGIN` and ends with `COMMIT` (save all changes) or `ROLLBACK` (undo all changes). Until a transaction commits, its changes are invisible to other users.

| ACID property | Meaning | Demonstrated in |
|---|---|---|
| Atomicity | All statements succeed, or none take effect | Experiments 1, 2a, 2b |
| Consistency | Rules (CHECK, foreign keys) hold after every transaction | Experiment 2b |
| Isolation | Concurrent transactions do not interfere | Experiment 3 |
| Durability | Committed changes are permanent | Experiment 1 |

## Setup

A test course, CSC 499 (Special Topics Seminar), was created with an offering in 2025/2026 semester 1 with a **capacity of 3**, so that a full class could be demonstrated.

## Experiment 1: COMMIT

Two students (LMU/2021/00001 and LMU/2022/00002) were registered for CSC 499 inside one transaction, then committed. Both registrations were saved together and remained after the transaction ended.

**Shows:** atomicity and durability.

## Experiment 2a: Manual ROLLBACK

**Scenario:** an exams officer accidentally publishes the 2025/2026 CSC 202 results, which are still in draft.

1. Inside a transaction, the results were updated to `published`.
2. A check inside the same transaction confirmed the change.
3. `ROLLBACK` was issued.
4. The results returned to `draft`.

Because the change was never committed, no other user ever saw the unapproved results.

**Shows:** atomicity, and that uncommitted changes are isolated from other users.

## Experiment 2b: Automatic rollback

**Scenario:** a lecturer uploads scores for CSC 499 in one batch. The first score is valid; the second has a typo (exam score 75).

1. The first INSERT (exam score 45) succeeded.
2. The second INSERT (exam score 75) was rejected by the `chk_exam_score` CHECK constraint.
3. Any further statement returned: *"current transaction is aborted, commands ignored until end of transaction block."* PostgreSQL refuses to continue once a statement in a transaction has failed.
4. After `ROLLBACK`, the number of CSC 499 results was **0**. The valid first score was also undone.

Saving only half a batch would leave the class in an unclear state, with no record of which students still need scores. With atomicity, the lecturer corrects the typo and resubmits the whole batch.

**Shows:** atomicity and consistency (the Portfolio 1 CHECK rule prevented an invalid score from ever being stored).

## Experiment 3: Concurrency – two students, one seat

Two separate pgAdmin Query Tool sessions (Window A and Window B) acted as two students registering at the same time. CSC 499 had 2 of its 3 seats taken.

### 3a: Without locking – the problem

| Step | Window A | Window B |
|---|---|---|
| 1 | BEGIN; check seats: 2 of 3 taken | |
| 2 | | BEGIN; check seats: 2 of 3 taken |
| 3 | Register LMU/2023/00003; COMMIT | |
| 4 | | Register LMU/2024/00004; COMMIT |

**Result: capacity 3, taken 4. The course was overbooked.**

Both transactions read the seat count before either had committed, so both saw one free seat and acted on it. This is a **race condition**: each decision was based on data that was out of date by the time the transaction wrote. Under READ COMMITTED, each statement sees only data committed before it started, so neither session could see the other's uncommitted registration. The schema's constraints did not catch the problem, because the unique index only prevents the same student registering twice, and these were different students.

The two extra registrations were then deleted to restore 2 of 3 seats taken.

### 3b: With locking – the fix

| Step | Window A | Window B |
|---|---|---|
| 1 | BEGIN; `SELECT ... FOR UPDATE` on the CSC 499 offering (lock acquired) | |
| 2 | Check seats: 2 of 3 taken | |
| 3 | | BEGIN; `SELECT ... FOR UPDATE` on the same offering: **waits** |
| 4 | Register LMU/2023/00003; COMMIT (lock released) | |
| 5 | | Lock acquired; check seats: **3 of 3 taken** |
| 6 | | Course full, so no registration; ROLLBACK |

**Result: capacity 3, taken 3. The course was not overbooked.**

`SELECT ... FOR UPDATE` locks the offering row. A second transaction requesting the same lock must wait until the first commits or rolls back, so registrations for the same offering happen one after another instead of at the same time.

The lock was taken in its own statement, before the seat count. PostgreSQL fixes what a statement can see when the statement starts. If the lock and count were combined in one statement, Window B could start, wait, and then count using the old data from before Window A's registration. Running the lock first means Window B's count starts after the wait and includes Window A's committed registration.

## Isolation levels

PostgreSQL's default level, **READ COMMITTED**, prevents dirty reads: a transaction never sees another transaction's uncommitted changes. It does not stop two transactions making decisions from the same out-of-date information, as Experiment 3a showed. There are two standard solutions:

1. **Row locking** (`SELECT ... FOR UPDATE`), used here. The second transaction waits briefly, then proceeds with current data.
2. **The SERIALIZABLE isolation level.** PostgreSQL detects the conflict and cancels one transaction with an error, which the application must then retry.

Locking was chosen because, for course registration, a short wait is a better experience for the second student than an error and retry. The lock is held only for the duration of one registration, so waiting times are very short.

## Screenshots

| Evidence | File |
|---|---|
| Experiment 1: two students registered | `screenshots/01-commit.png` |
| Experiment 2a: results published inside transaction | `screenshots/02a-before-rollback.png` |
| Experiment 2a: results back to draft after rollback | `screenshots/02a-after-rollback.png` |
| Experiment 2b: CHECK constraint error | `screenshots/02b-check-error.png` |
| Experiment 2b: transaction aborted message | `screenshots/02b-aborted.png` |
| Experiment 2b: count of 0 after rollback | `screenshots/02b-after-rollback.png` |
| Experiment 3a: course overbooked (4 of 3) | `screenshots/03a-overbooked.png` |
| Experiment 3b: Window B waiting for the lock | `screenshots/03b-waiting.png` |
| Experiment 3b: course full (3 of 3) | `screenshots/03b-full.png` |

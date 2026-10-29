# Portfolio 1: Database Design and Modelling

**Case study:** Lagos Metropolitan University (LMU) Student Result Portal
**Database:** PostgreSQL
**Design tool:** dbdiagram.io (DBML)

## What this portfolio covers

This folder contains the relational design for the LMU Student Result Portal: the ER diagram, the relational schema with keys and constraints, tests showing the constraints work, and an explanation of how the design was normalised.

## Files in this folder

| File | Purpose |
|---|---|
| `er-diagram.png` | Entity-relationship diagram exported from dbdiagram.io |
| `schema.dbml` | DBML source used to build the diagram |
| `schema.sql` | PostgreSQL script that creates all tables, keys, constraints and loads the grading scale |
| `normalisation.md` | Step-by-step normalisation from an unnormalised result sheet to 3NF |
| `screenshots/` | Evidence that the schema runs and the constraints are enforced |

## Design summary

The database has 11 tables:

- **Organisation structure:** `faculty` → `department` → `programme`
- **People:** `student` (belongs to a programme), `lecturer` (belongs to a department)
- **Teaching:** `course` (owned by a department), `academic_session`, `course_offering` (a course taught in a specific session and semester by a specific lecturer)
- **Records:** `registration` (a student enrolled on a course offering), `result` (scores for one registration)
- **Reference:** `grade_scale` (the university's 5-point grading chart)

### Key design decisions

1. **Surrogate keys for most tables.** Tables such as `student` use an auto-generated integer ID instead of the matric number. Matric numbers can change (programme transfers, format corrections), and integer keys make joins faster. `matric_no` is still enforced as UNIQUE and NOT NULL.
2. **Natural key for course.** `course_code` (e.g. CSC 201) is used as the primary key because course codes are short, stable and meaningful. The foreign key from `course_offering` uses `ON UPDATE CASCADE`, so a renamed course code updates automatically.
3. **Course vs course offering.** A course exists once, but it is offered every session, sometimes by a different lecturer. Students register for the offering, not the course, so the lecturer is stored on `course_offering`.
4. **Many-to-many resolved by registration.** A student takes many course offerings, and an offering has many students. The `registration` table links them, with a composite UNIQUE rule on `(student_id, offering_id)` so a student cannot register for the same offering twice.
5. **One-to-one between registration and result.** Results are kept in a separate table because registrations are created at the start of the semester, while scores only exist after assessment.
6. **Grades are derived, not stored.** `result` stores only the CA and exam scores. The grade and grade point are looked up from `grade_scale` by score range, so they can never fall out of sync with the scores.
7. **Scores are nullable.** CA scores are entered during the semester and exam scores later, so both may be blank while a result is in draft.
8. **ON DELETE RESTRICT on all foreign keys.** Academic records should never be deleted by accident. Instead of deleting, records change status (for example, a registration becomes `dropped`).

## Constraints

| Table | Constraint | Rule |
|---|---|---|
| course | chk_credit_units | Credit units between 1 and 6 |
| course_offering | chk_semester | Semester is 1 or 2 |
| course_offering | chk_capacity | Capacity greater than 0 |
| course_offering | unique index | One offering per course, session and semester |
| registration | chk_reg_status | Status is registered or dropped |
| registration | unique index | One registration per student per offering |
| result | chk_ca_score | CA score between 0 and 40 |
| result | chk_exam_score | Exam score between 0 and 60 |
| result | chk_result_status | Status is draft, approved or published |
| academic_session | chk_session_dates | End date after start date |
| grade_scale | chk_min_score, chk_max_score, chk_score_range, chk_grade_point | Valid score ranges and grade points |

## How to run

1. In pgAdmin, create a database called `lmu_result_portal`.
2. Select the database and open **Tools → Query Tool**.
3. Open `schema.sql` and run it (F5).
4. Refresh **Schemas → public → Tables** to confirm all 11 tables exist.

Note: the script begins by dropping all tables so it can be rerun cleanly. Do not run it on a database containing data you want to keep.

## Tests and evidence

| Test | Expected result | Screenshot |
|---|---|---|
| Run `schema.sql` | All 11 tables created | `screenshots/01-tables-created.png` |
| `SELECT * FROM grade_scale;` | Six grade rows returned | `screenshots/02-grade-scale.png` |
| Insert a course with 9 credit units | Rejected by `chk_credit_units` | `screenshots/03-check-constraint.png` |
| Delete a faculty that still has departments | Rejected by foreign key (RESTRICT) | `screenshots/04-restrict-delete.png` |
| Rename CSC 201 to CSC 211 | Course offering updates automatically (CASCADE) | `screenshots/05-cascade-update.png` |

## Normalisation

See [`normalisation.md`](normalisation.md) for how the design was taken from an unnormalised result sheet to Third Normal Form.

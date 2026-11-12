Markdown · README.md

# Portfolio 4: NoSQL and Advanced Data Models

**Case study:** Lagos Metropolitan University (LMU) Student Result Portal **Database:** MongoDB Atlas (free M0 cluster), accessed through MongoDB Compass and its built-in shell (mongosh)

## What this portfolio covers

This folder models the same result portal as a document database, compares the document model with the relational design from Portfolio 1, and tests querying, indexing, aggregation and updates on 10,003 student transcript documents.

## Files in this folder

| File | Purpose |
| --- | --- |
| `01_insert_documents.js` | Three hand-written transcript documents, showing embedding and a flexible schema |
| `02_queries.js` | Basic queries: dot notation, projection, `$elemMatch`, `$exists`, `$gte` and sort |
| `03_generate_transcripts.js` | Generates 10,000 transcript documents |
| `04_indexes_and_reports.js` | Index tests with `explain()`, aggregation reports, and the department rename test |
| `screenshots/` | Evidence for each step |

## Document design

Each student is stored as **one document** in a `transcripts` collection. Semesters are embedded inside the student, and courses inside each semester:

```
transcript
├── matric_no, name { first, last }
├── programme, department, faculty, entry_year
├── semesters [ ]
│     ├── session, semester, gpa
│     └── courses [ ]
│           └── course_code, title, units, ca, exam, total, grade, grade_point
└── cgpa
```

| PostgreSQL | MongoDB |
| --- | --- |
| Table | Collection |
| Row | Document |
| Column | Field |
| Joins across 7 tables | Data embedded in one document |
| Primary key | `_id` (created automatically) |

### Design decisions

1. **Embedding instead of joins.** The whole transcript is stored in the shape it is displayed, so reading a transcript is one lookup. In PostgreSQL, the same transcript needs joins across student, registration, result, course_offering, course, academic_session and grade_scale.
2. **Derived values are stored.** `total`, `grade`, `grade_point`, `gpa` and `cgpa` are calculated once when the document is created, then stored. Portfolio 1 deliberately avoided storing these so they could never be out of date. Here they are stored because transcripts are read far more often than published results change. The cost is that correcting a score requires the application to update the grade, GPA and CGPA as well.
3. **Descriptive data is duplicated.** Department, faculty and course titles are repeated in every student's document. This is the duplication that normalisation removed in Portfolio 1.
4. **Flexible schema.** Documents in the same collection can have different fields. One student has a `scholarship`, another has a `hall_of_residence` and no results yet. MongoDB accepts them all, with no ALTER TABLE needed. However, MongoDB also accepts mistakes, such as a misspelled field name, that PostgreSQL's schema and CHECK constraints would reject.

## Queries

| Query | Purpose | Feature |
| --- | --- | --- |
| `findOne({ matric_no })` | One student's full transcript | Single lookup, no joins |
| `"semesters.courses.course_code"` | Everyone who took CSC 101 | Dot notation into nested arrays; projection |
| `$elemMatch` | Students with an A in CSC 101 | Both conditions must match the same array element |
| `$exists` | Students with a scholarship | Querying a field only some documents have |
| `$gte` with `.sort()` | Students with CGPA ≥ 3.5, highest first | Comparison operators and sorting |

**A pitfall with nested data.** A query for `course_code: "CSC 101"` and `grade: "A"` without `$elemMatch` returned 2 students, including one who scored a C in CSC 101 and an A in a different course. Without `$elemMatch`, each condition is checked against the whole array separately, so they can be satisfied by different courses. With `$elemMatch`, both must be true of the same course, and only the correct student was returned.

## Test dataset

`03_generate_transcripts.js` generates 10,000 transcripts: six departments (one or two per faculty), entry years 2020 to 2025, two semesters per completed year and five courses per semester, with random CA (10–40) and exam (15–60) scores. Grades and GPAs are calculated with the same 5-point scale and weighted-average formula used in PostgreSQL. Together with the three hand-written documents, the collection holds 10,003 documents.

Unlike PostgreSQL's `setseed()`, JavaScript's `Math.random()` cannot be seeded, so each run produces different scores. Before and after comparisons were therefore always made on the same loaded data.

**A data generation error, found and fixed.** The first version of the generator used `i % 6` for both the department and the entry year, so every student in a department shared the same entry year. The index test revealed it: every Computer Science student (1,667) had taken CSC 201, and the Faculty of Arts had no results at all. The entry year was changed to `2020 + (Math.floor(i / 6) % 6)`, so each department now has students from every year, and the data was regenerated. This showed the importance of sanity-checking generated test data before relying on it.

## Indexing

Measured with `.explain("executionStats")`.

| Query | Before index | After index |
| --- | --- | --- |
| One student by matric_no | COLLSCAN, 10,003 documents examined, 1 returned | EXPRESS_IXSCAN, 1 document examined, 1 returned |
| Everyone who took CSC 201 | COLLSCAN, 10,003 documents examined, 1,112 returned | FETCH via index, 1,112 documents examined, 1,112 returned |

- **matric_no** was indexed with `{ unique: true }`. This makes lookups direct and also rejects duplicate matric numbers. MongoDB's flexible schema does not otherwise prevent duplicates.
- **semesters.courses.course_code** is a **multikey index**: MongoDB creates an index entry for every course in every document. Documents examined fell from 10,003 to exactly the 1,112 matching students. The index is larger than a normal one, because it holds one entry per course rather than one per student.
- Execution times were 0–11 ms and are rounded to whole milliseconds, so documents examined is the more reliable measure.
- When searching for a matric number that does not exist, the index also answered immediately (0 documents examined), whereas a collection scan must read every document to be sure.

## Aggregation

**Report 1: average CGPA per faculty** (`$match` → `$group` → `$sort`)

| Faculty | Students | Average CGPA |
| --- | --- | --- |
| Faculty of Arts | 1,389 | 3.46 |
| Faculty of Management Sciences | 1,388 | 3.46 |
| Faculty of Social Sciences | 1,388 | 3.46 |
| Faculty of Engineering | 1,389 | 3.45 |
| Faculty of Science | 2,780 | 3.44 |

Science has about twice as many students because it has two departments; its 2,780 includes the two hand-written Computer Science students. No joins were needed, because faculty is stored in each document. The averages are similar because the scores are random.

**Report 2: grade distribution for CSC 201 in 2024/2025** (`$unwind` → `$unwind` → `$match` → `$group` → `$sort`)

| Grade | Students |
| --- | --- |
| A | 100 |
| B | 61 |
| C | 56 |
| D | 15 |
| E | 15 |
| F | 31 |
| **Total** | **278** |

`$unwind` turns one document containing an array into one document per array element. Unwinding semesters and then courses produced one document per student per course: the same shape as the registration and result rows in PostgreSQL. To answer a question about a **course** rather than a **student**, the nested documents had to be taken apart first. The document model is fast for the access pattern it was designed for and more work for others.

## Update test: renaming a department

```javascript
db.transcripts.updateMany(
  { department: "Computer Science" },
  { $set: { department: "Computer Science and Informatics" } }
)
```

**Result: 1,669 documents modified.** In PostgreSQL, the same change updates one row in the department table. This is the update anomaly that normalisation prevents: because the department name is duplicated in every student's document, every copy must be changed. Renaming a course title would be harder still, since titles are repeated inside nested arrays in thousands of documents. The change was then reversed.

## Relational vs document model

|  | PostgreSQL (Portfolios 1–3) | MongoDB (Portfolio 4) |
| --- | --- | --- |
| Reading one transcript | Joins across 7 tables | One document lookup |
| Course-based questions (result sheets, pass rates) | Natural, through joins | Requires `$unwind` to take documents apart |
| Changing shared data (department name) | 1 row | 1,669 documents |
| Data integrity | Enforced by foreign keys, CHECK and UNIQUE | Mostly the application's responsibility; unique indexes available |
| Schema changes | ALTER TABLE | Add the field to new documents |
| Multi-step changes | ACID transactions (Portfolio 3) | Single-document updates are atomic; multi-document transactions exist but are used less |
| Derived values (grades, GPA) | Calculated on demand, always current | Stored, so they must be kept in sync |

## When to use which

For the LMU portal, **PostgreSQL should remain the system of record**. Score entry, approval, registration with capacity limits and corrections all need strict rules, joins across many entities, and the transactions demonstrated in Portfolio 3.

MongoDB suits a **read-optimised copy** of published transcripts. On result-release day, thousands of students each read their own transcript, which the document model answers in a single lookup with no joins and no grade calculation. Because published results rarely change, the cost of duplicated and stored values is low. This copy could be rebuilt from PostgreSQL whenever results are published, similar to the materialized view in Portfolio 2.

**Embedding vs referencing.** Semesters and courses are embedded because they belong to one student and are always read with the transcript. Data shared by many students and likely to change, such as lecturer details or the course catalogue, would be better kept in separate collections and referenced by ID, accepting an extra lookup in exchange for a single place to update.

## Screenshots

| Evidence | File |
| --- | --- |
| Three hand-written documents in Compass | `screenshots/01-three-documents.png` |
| `$elemMatch` comparison (2 results vs 1) | `screenshots/02-elemmatch.png` |
| 10,003 documents after generation | `screenshots/03-generated.png` |
| matric_no explain, before and after index | `screenshots/04-matric-index.png` |
| CSC 201 explain, before and after multikey index | `screenshots/05-multikey-index.png` |
| Report 1: average CGPA per faculty | `screenshots/06-report-cgpa.png` |
| Report 2: CSC 201 grade distribution | `screenshots/07-report-grades.png` |
| Department rename: 1,669 documents modified | `screenshots/08-rename.png` |
# Advanced Database Systems Portfolio
**MIT 8103 – Advanced Database Systems**
Master of Information Technology, MIVA Open University
2026/2027 Academic Session, First Semester

**Student:** Akinfoyewa Iyanuoluwa
**Matric No:** 2026/A/MIT/0818

---

## Case Study: Lagos Metropolitan University (LMU) Student Result Portal

**Organisation:** Lagos Metropolitan University (LMU) is a simulated university organised into faculties, departments and degree programmes. This portfolio designs and builds the database behind its Student Result Portal.

**Nature of the system:** The portal manages the full academic record cycle, from course registration at the start of each semester to score entry, result approval, GPA/CGPA computation and transcript generation.

**Users of the database:**
- **Students** register for courses and view their results and transcripts.
- **Lecturers** enter continuous assessment (CA) and exam scores for the courses they teach.
- **Heads of Department** review and approve results.
- **Exams and Records Officers** publish results and issue transcripts.

**Major data stored:**
- Faculties, departments and programmes
- Students and lecturers
- Courses and course offerings per academic session and semester
- Course registrations
- CA scores, exam scores and result status
- The university grading scale (5-point scale)

**Key operations supported:**
- Register students for course offerings (with capacity limits)
- Enter, approve and publish scores
- Derive grades and grade points from total scores
- Compute GPA per semester and CGPA across sessions
- Generate student transcripts
- Rank students by CGPA and class of degree

---

## Repository Structure

```
advanced-database-portfolio/
├── portfolio-1-database-design/      ER diagram, DBML, schema, constraints, normalisation
├── portfolio-2-query-optimisation/   SQL queries, execution plans, indexing results
├── portfolio-3-transactions-concurrency/   Commit, rollback, isolation and locking evidence
├── portfolio-4-nosql/                MongoDB document model and queries
├── portfolio-5-distributed-cloud/    Replication, sharding and cloud deployment evidence
└── README.md                         This file
```

Each portfolio folder has its own README explaining what was done, how it was tested and what the evidence shows.

---

## Portfolio Progress

| Portfolio | Activity | Status |
|---|---|---|
| 1 | Database Design and Modelling | Completed |
| 2 | Query Processing and Optimisation | Completed |
| 3 | Transactions and Concurrency | In Progress |
| 4 | NoSQL and Advanced Data Models | Not started |
| 5 | Distributed and Cloud Database Exercise | Not started |
| – | Final Documentation and Reflection | Not started |

---

## Tools and Technologies

- **PostgreSQL** – relational database (Portfolios 1–3)
- **dbdiagram.io (DBML)** – ER diagram design
- **MongoDB / MongoDB Atlas** – NoSQL and cloud database (Portfolios 4–5)
- **GitHub** – version control and progressive submission

---

## How to Run the Relational Schema

1. Create a database in PostgreSQL:
   ```sql
   CREATE DATABASE lmu_result_portal;
   ```
2. Run the schema script from the portfolio 1 folder:
   ```
   psql -d lmu_result_portal -f portfolio-1-database-design/schema.sql
   ```
3. Load sample data (once added):
   ```
   psql -d lmu_result_portal -f portfolio-1-database-design/seed_data.sql
   ```

---

## AI Use Declaration

- **AI tool used:** Claude (Anthropic)
- **What it was used for:** Explaining database concepts such as primary keys, foreign keys and normalisation; reviewing my DBML design for errors; drafting README structure, learning the syntax of DBML and SQL
- **How output was verified:**  I wrote and ran all scripts myself in PostgreSQL, tested every constraint with deliberate invalid inserts, and revised the design where I disagreed with or did not understand a suggestion

---

## References

- PostgreSQL Global Development Group. *PostgreSQL Documentation.* https://www.postgresql.org/docs/
- Holistics. *DBML – Database Markup Language Documentation.* https://dbml.dbdiagram.io/docs
- MongoDB Inc. *MongoDB Documentation.* https://www.mongodb.com/docs/

# Normalisation Explanation

This document shows how the LMU Student Result Portal design was derived by normalising a typical unnormalised result sheet up to Third Normal Form (3NF).

## Starting point: an unnormalised result sheet

Before a database, a department might keep results in a single spreadsheet like this:

| Matric No | Student Name | Programme | Department | Faculty | Courses Taken | Session | Semester | Lecturer | Scores | Grade |
|---|---|---|---|---|---|---|---|---|---|---|
| LMU/23/001 | Tolu Ade | B.Sc. Cybersecurity | Computer Science | Science | CSC 201, MTH 202 | 2025/2026 | 1 | Dr. Adeyemi, Dr. Bello | 25+43, 30+38 | B, B |
| LMU/23/002 | Musa Ibrahim | B.Sc. Computer Science | Computer Science | Science | CSC 201 | 2025/2026 | 1 | Dr. Adeyemi | 35+40 | A |

Problems with this sheet:

- **Several values in one cell.** "CSC 201, MTH 202" and "25+43, 30+38" cannot be searched, sorted or totalled reliably.
- **Repetition.** "Computer Science" and "Science" are repeated for every student. Dr. Adeyemi is repeated for every student taking CSC 201.
- **Update anomaly.** If the Faculty of Science is renamed, every row must be changed. Missing one leaves the data inconsistent.
- **Insertion anomaly.** A new course cannot be recorded until a student takes it, because courses only exist inside student rows.
- **Deletion anomaly.** If Musa's row is deleted, the fact that Dr. Adeyemi teaches CSC 201 could be lost along with it.

## First Normal Form (1NF)

**Rule:** every cell holds a single value, and there are no repeating groups.

Each course a student takes becomes its own row, and the combined scores are split into separate CA and exam columns:

| Matric No | Student Name | Programme | Department | Faculty | Course Code | Course Title | Credit Units | Session | Semester | Lecturer | CA | Exam | Grade |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| LMU/23/001 | Tolu Ade | B.Sc. Cybersecurity | Computer Science | Science | CSC 201 | Data Structures | 3 | 2025/2026 | 1 | Dr. Adeyemi | 25 | 43 | B |
| LMU/23/001 | Tolu Ade | B.Sc. Cybersecurity | Computer Science | Science | MTH 202 | Linear Algebra | 3 | 2025/2026 | 1 | Dr. Bello | 30 | 38 | B |
| LMU/23/002 | Musa Ibrahim | B.Sc. Computer Science | Computer Science | Science | CSC 201 | Data Structures | 3 | 2025/2026 | 1 | Dr. Adeyemi | 35 | 40 | A |

The table is now in 1NF. The key that identifies each row is the combination **(Matric No, Course Code, Session, Semester)**. However, there is still a lot of repetition.

## Second Normal Form (2NF)

**Rule:** the table is in 1NF, and every non-key column depends on the *whole* key, not just part of it (no partial dependencies).

Several columns depend on only part of the composite key:

- **Student Name, Programme, Department, Faculty** depend only on **Matric No**.
- **Course Title, Credit Units** depend only on **Course Code**.
- **Lecturer** depends on **Course Code + Session + Semester**, not on the student.

Only **CA, Exam and Grade** depend on the full key, because they describe one student's performance in one course offering.

To remove the partial dependencies, the table is split:

- **Student** (matric_no, name, programme, department, faculty)
- **Course** (course_code, title, credit_units)
- **Course Offering** (course_code, session, semester, lecturer)
- **Registration/Result** (matric_no, course_code, session, semester, ca_score, exam_score, grade)

## Third Normal Form (3NF)

**Rule:** the table is in 2NF, and no non-key column depends on another non-key column (no transitive dependencies).

Three transitive dependencies remain:

1. **Student → Programme → Department → Faculty.** A student's department and faculty are determined by their programme, not by the student directly. Storing them on the student row repeats them thousands of times. They are moved into separate `programme`, `department` and `faculty` tables, and the student stores only `programme_id`.
2. **Score → Grade.** The grade depends on the total score (CA + exam), not on the registration itself. Storing it creates a risk: if a score is corrected from 43 to 47, the total moves from 68 to 72 and the grade should change from B to A, but a stored "B" would remain unless someone remembers to update it. The grade is therefore removed from the result table and looked up from a separate `grade_scale` table by score range.
3. **Lecturer details.** The lecturer's name, rank and department depend on the lecturer, not the course offering. A separate `lecturer` table is created, and the offering stores only `lecturer_id`.

Two further improvements were made for practical reasons:

- **Surrogate keys.** Auto-generated IDs replace matric numbers and multi-column keys as primary keys in most tables, because matric numbers can change and integer keys make joins faster. Course codes are kept as a natural key because they are stable.
- **Registration and result separated.** Registration records exist from the start of the semester, while results only exist after assessment, so they are held in separate tables with a one-to-one link.

## Final design in 3NF

| Table | Primary key | Depends only on the key |
|---|---|---|
| faculty | faculty_id | name |
| department | dept_id | name, faculty_id |
| programme | programme_id | name, dept_id, duration_years |
| student | student_id | matric_no, names, email, programme_id, entry_year, current_level |
| lecturer | lecturer_id | staff_no, names, email, academic_rank, dept_id |
| course | course_code | title, credit_units, level, dept_id |
| academic_session | session_id | name, start_date, end_date |
| course_offering | offering_id | course_code, session_id, semester, lecturer_id, capacity |
| registration | registration_id | student_id, offering_id, reg_date, status |
| result | result_id | registration_id, ca_score, exam_score, status, entered_by, entered_at |
| grade_scale | grade | min_score, max_score, grade_point |

Every non-key column in each table describes only the thing that table's key identifies. Every determinant is also a candidate key (for example, `matric_no` in `student` and `(course_code, session_id, semester)` in `course_offering` are enforced as UNIQUE), so the tables also satisfy Boyce-Codd Normal Form (BCNF).

## Values deliberately not stored

- **Total score** (CA + exam) is calculated in queries.
- **Grade and grade point** are looked up from `grade_scale`.
- **GPA and CGPA** are calculated from credit units and grade points.

Storing these would duplicate information that can be derived and could fall out of sync. Whether any of them should be stored later for performance (denormalisation) is considered in Portfolio 2.

## How the anomalies are resolved

| Anomaly in the original sheet | How the design resolves it |
|---|---|
| Renaming a faculty means editing every row | Faculty name is stored once in `faculty` |
| A new course can't exist until a student takes it | Courses are stored independently in `course` |
| Deleting a student loses lecturer information | Lecturer data is stored in `lecturer` and `course_offering` |
| Correcting a score leaves the wrong grade | Grades are derived from `grade_scale`, never stored |

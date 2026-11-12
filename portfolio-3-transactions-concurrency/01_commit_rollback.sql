INSERT INTO course (course_code, title, credit_units, level, dept_id)
VALUES ('CSC 499', 'Special Topics Seminar', 2, 400, 1);

INSERT INTO course_offering (course_code, session_id, semester, lecturer_id, capacity)
SELECT 'CSC 499', s.session_id, 1, l.lecturer_id, 3
FROM academic_session s, lecturer l
WHERE s.name = '2025/2026' AND l.staff_no = 'LMU/STF/0101';

BEGIN;

INSERT INTO registration (student_id, offering_id)
SELECT s.student_id, o.offering_id
FROM student s, course_offering o
WHERE s.matric_no IN ('LMU/2021/00001', 'LMU/2022/00002')
  AND o.course_code = 'CSC 499';


COMMIT;

SELECT s.matric_no, r.status, r.reg_date
FROM registration r
JOIN student s         ON s.student_id = r.student_id
JOIN course_offering o ON o.offering_id = r.offering_id
WHERE o.course_code = 'CSC 499';

BEGIN;

UPDATE result r
SET status = 'published'
FROM registration reg
JOIN course_offering o  ON o.offering_id = reg.offering_id
JOIN academic_session s ON s.session_id = o.session_id
WHERE r.registration_id = reg.registration_id
  AND o.course_code = 'CSC 202'
  AND s.name = '2025/2026';

ROLLBACK;

SELECT r.status, count(*)
FROM result r
JOIN registration reg  ON reg.registration_id = r.registration_id
JOIN course_offering o ON o.offering_id = reg.offering_id
JOIN academic_session s ON s.session_id = o.session_id
WHERE o.course_code = 'CSC 202' AND s.name = '2025/2026'
GROUP BY r.status;

BEGIN;

-- Valid score for the first student
INSERT INTO result (registration_id, ca_score, exam_score, entered_by)
SELECT r.registration_id, 30, 45, o.lecturer_id
FROM registration r
JOIN course_offering o ON o.offering_id = r.offering_id
JOIN student s         ON s.student_id = r.student_id
WHERE o.course_code = 'CSC 499' AND s.matric_no = 'LMU/2021/00001';

-- Typo: exam score 75
INSERT INTO result (registration_id, ca_score, exam_score, entered_by)
SELECT r.registration_id, 30, 75, o.lecturer_id
FROM registration r
JOIN course_offering o ON o.offering_id = r.offering_id
JOIN student s         ON s.student_id = r.student_id
WHERE o.course_code = 'CSC 499' AND s.matric_no = 'LMU/2022/00002';

SELECT count(*) FROM result;

ROLLBACK;

SELECT count(*)
FROM result r
JOIN registration reg  ON reg.registration_id = r.registration_id
JOIN course_offering o ON o.offering_id = reg.offering_id
WHERE o.course_code = 'CSC 499';
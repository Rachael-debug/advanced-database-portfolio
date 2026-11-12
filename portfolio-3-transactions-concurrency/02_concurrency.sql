-- WINDOW A
BEGIN;

SELECT o.capacity,
       (SELECT count(*) FROM registration r
        WHERE r.offering_id = o.offering_id AND r.status = 'registered') AS taken
FROM course_offering o
WHERE o.course_code = 'CSC 499';

INSERT INTO registration (student_id, offering_id)
SELECT s.student_id, o.offering_id
FROM student s, course_offering o
WHERE s.matric_no = 'LMU/2023/00003' AND o.course_code = 'CSC 499';

COMMIT;

-- WINDOW B
BEGIN;

-- the same seat check as Window A
SELECT o.capacity,
       (SELECT count(*) FROM registration r
        WHERE r.offering_id = o.offering_id AND r.status = 'registered') AS taken
FROM course_offering o
WHERE o.course_code = 'CSC 499';

INSERT INTO registration (student_id, offering_id)
SELECT s.student_id, o.offering_id
FROM student s, course_offering o
WHERE s.matric_no = 'LMU/2024/00004' AND o.course_code = 'CSC 499';

COMMIT;

-- Reseting extra registrations
DELETE FROM registration r
USING student s, course_offering o
WHERE r.student_id = s.student_id
  AND r.offering_id = o.offering_id
  AND o.course_code = 'CSC 499'
  AND s.matric_no IN ('LMU/2023/00003', 'LMU/2024/00004');

-- WINDOW A
BEGIN;

SELECT offering_id, capacity
FROM course_offering
WHERE course_code = 'CSC 499'
FOR UPDATE;

INSERT INTO registration (student_id, offering_id)
SELECT s.student_id, o.offering_id
FROM student s, course_offering o
WHERE s.matric_no = 'LMU/2023/00003' AND o.course_code = 'CSC 499';

COMMIT;

-- WINDOW B
BEGIN;

SELECT offering_id, capacity
FROM course_offering
WHERE course_code = 'CSC 499'
FOR UPDATE;

ROLLBACK;
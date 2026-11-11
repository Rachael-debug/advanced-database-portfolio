INSERT INTO faculty (name) VALUES
	('Faculty of Science'),
	('Faculty of Engineering'),
	('Faculty of Social Sciences'),
	('Faculty of Management Sciences'),
	('Faculty of Arts');

INSERT INTO department (name, faculty_id) VALUES
	('Computer Science', 1), ('Mathematics', 1), ('Physics', 1), ('Microbiology', 1),
	('Electrical Engineering', 2), ('Mechanical Engineering', 2), ('Civil Engineering', 2), ('Chemical Engineering', 2),
	('Economics', 3), ('Political Science', 3), ('Sociology', 3), ('Psychology', 3),
	('Accounting', 4), ('Business Administration', 4), ('Banking and Finance', 4), ('Marketing', 4),
	('English', 5), ('History', 5), ('Philosophy', 5), ('Theatre Arts', 5);

INSERT INTO programme (name, dept_id, duration_years)
SELECT 'B.Sc. ' || name, dept_id, 4
FROM department;

INSERT INTO lecturer (staff_no, first_name, last_name, email, academic_rank, dept_id)
SELECT
	'LMU/STF/' || lpad((d.dept_id * 100 + n)::text, 4, '0'),
	(ARRAY['Bola','Chinedu','Funke','Ibrahim','Ngozi','Segun','Amaka','Yusuf','Kemi','Emeka'])[n],
	(ARRAY['Adeyemi','Okafor','Bello','Eze','Lawal','Okeke','Balogun','Musa','Adebayo','Nwosu'])[1+ (d.dept_id + n) % 10],
	'staff' || d.dept_id || '_' || n || '@lmu.edu.ng',
	(ARRAY['Professor','Reader','Senior Lecturer','Lecturer I','Lecturer II'])[1 + n % 5],
	d.dept_id
FROM department d
CROSS JOIN generate_series(1, 10) AS n;

SELECT setseed(0.42);

INSERT INTO course (course_code, title, credit_units, level, dept_id)
SELECT
	p.prefix || ' ' || (lvl / 100) || lpad(n::text, 2, '0'),
	d.name || ' ' || lvl || ' Course ' || n,
	2 + floor(random()*3)::int,
	lvl,
	d.dept_id
FROM department d
JOIN (VALUES
	(1,'CSC'),(2,'MTH'),(3,'PHY'),(4,'MCB'),(5,'EEE'),(6,'MEE'),(7,'CVE'),(8,'CHE'),(9,'ECO'),(10,'POL'),
  	(11,'SOC'),(12,'PSY'),(13,'ACC'),(14,'BUS'),(15,'BFN'),(16,'MKT'),(17,'ENG'),(18,'HIS'),(19,'PHL'),(20,'THA')
) AS p(dept_id, prefix) ON p.dept_id = d.dept_id
CROSS JOIN generate_series(100, 400, 100) AS lvl
CROSS JOIN generate_series(1, 10) AS n;

INSERT INTO academic_session (name, start_date, end_date)
SELECT y || '/' || (y+1), make_date(y, 10, 1), make_date(y + 1, 7, 31)
FROM generate_series(2020, 2025) AS y;

INSERT INTO course_offering (course_code, session_id, semester, lecturer_id, capacity)
SELECT
	c.course_code,
	s.session_id,
	CASE WHEN right(c.course_code, 2)::int % 2 = 1 THEN 1 ELSE 2 END,
	l.lecturer_id,
	200
FROM course c
CROSS JOIN academic_session s
JOIN lecturer l
	ON l.staff_no ='LMU/STF/' ||lpad((c.dept_id * 100 + 1 + (right(c.course_code, 2)::int + s.session_id) % 10)::text, 4, '0');

SELECT setseed(0.42);

INSERT INTO student (matric_no, first_name, last_name, email, programme_id, entry_year, current_level)
SELECT
  'LMU/' || (2020 + n % 6) || '/' || lpad(n::text, 5, '0'),
  (ARRAY['Tolu','Musa','Chioma','Ade','Fatima','Obinna','Zainab','Tunde','Ifeoma','Sani'])[1 + floor(random() * 10)::int],
  (ARRAY['Adeyemi','Ibrahim','Okafor','Bello','Eze','Lawal','Okeke','Abubakar','Balogun','Nwosu'])[1 + floor(random() * 10)::int],
  'student' || n || '@students.lmu.edu.ng',
  1 + floor(random() * 20)::int,
  2020 + n % 6,
  LEAST((2025 - (2020 + n % 6) + 1) * 100, 400)
FROM generate_series(1, 10000) AS n;

INSERT INTO registration (student_id, offering_id, reg_date, status)
SELECT
  st.student_id,
  o.offering_id,
  sess.start_date + floor(random() * 21)::int,
  CASE WHEN random() < 0.01 THEN 'dropped' ELSE 'registered' END
FROM student st
JOIN programme p ON p.programme_id = st.programme_id
JOIN academic_session sess
  ON extract(year FROM sess.start_date) BETWEEN st.entry_year AND st.entry_year + 3
JOIN course c
  ON c.dept_id = p.dept_id
 AND c.level = (extract(year FROM sess.start_date) - st.entry_year + 1) * 100
JOIN course_offering o
  ON o.course_code = c.course_code
 AND o.session_id = sess.session_id;

INSERT INTO result (registration_id, ca_score, exam_score, status, entered_by, entered_at)
SELECT
  r.registration_id,
  10 + floor(random() * 31)::int,
  CASE WHEN s.name = '2025/2026' AND o.semester = 2 THEN NULL
       ELSE 15 + floor(random() * 46)::int END,
  CASE WHEN s.name <> '2025/2026' THEN 'published'
       WHEN o.semester = 1 THEN 'approved'
       ELSE 'draft' END,
  o.lecturer_id,
  s.start_date + CASE WHEN o.semester = 1 THEN 120 ELSE 270 END
FROM registration r
JOIN course_offering o ON o.offering_id = r.offering_id
JOIN academic_session s ON s.session_id = o.session_id
WHERE r.status = 'registered';
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
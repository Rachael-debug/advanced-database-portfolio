-- view for grades
CREATE OR REPLACE VIEW v_result_grade AS
SELECT
  r.result_id,
  r.registration_id,
  reg.student_id,
  reg.offering_id,
  r.ca_score,
  r.exam_score,
  r.ca_score + r.exam_score AS total_score,
  g.grade,
  g.grade_point,
  r.status
FROM result r
JOIN registration reg ON reg.registration_id = r.registration_id
LEFT JOIN grade_scale g
  ON r.ca_score + r.exam_score BETWEEN g.min_score AND g.max_score;

-- Q1, a student's transcript
SELECT sess.name AS session, o.semester, c.course_code, c.title, c.credit_units, v.total_score, v.grade, v.grade_point
FROM student s
JOIN v_result_grade v  		ON v.student_id = s.student_id
JOIN course_offering o 		ON o.offering_id = v.offering_id
JOIN course c          		ON c.course_code = o.course_code
JOIN academic_session sess	ON sess.session_id = o.session_id
WHERE s.matric_no = 'LMU/2022/00002'
ORDER BY sess.start_date, o.semester, c.course_code;

-- Q2, a course result sheet
SELECT s.matric_no, s.last_name, s.first_name,
       v.ca_score, v.exam_score, v.total_score, v.grade
FROM course_offering o
JOIN academic_session sess ON sess.session_id = o.session_id
JOIN v_result_grade v      ON v.offering_id = o.offering_id
JOIN student s             ON s.student_id = v.student_id
WHERE o.course_code = 'CSC 201' AND sess.name = '2024/2025'
ORDER BY s.matric_no;

--Q3, the top 10 students in a programme
SELECT matric_no, first_name, last_name, cgpa, position
FROM (
  SELECT s.matric_no, s.first_name, s.last_name,
         round(sum(c.credit_units * v.grade_point)::numeric / sum(c.credit_units), 2) AS cgpa,
         RANK() OVER (ORDER BY sum(c.credit_units * v.grade_point)::numeric / sum(c.credit_units) DESC) AS position
  FROM student s
  JOIN v_result_grade v  ON v.student_id = s.student_id
  JOIN course_offering o ON o.offering_id = v.offering_id
  JOIN course c          ON c.course_code = o.course_code
  WHERE s.programme_id = 1 AND v.grade IS NOT NULL
  GROUP BY s.student_id, s.matric_no, s.first_name, s.last_name
) ranked
WHERE position <= 10;

-- Q4, the pass rate per faculty
EXPLAIN ANALYZE
SELECT f.name AS faculty,
       count(*) AS results,
       round(100.0 * count(*) FILTER (WHERE v.grade <> 'F') / count(*), 1) AS pass_rate_pct
FROM v_result_grade v
JOIN course_offering o     ON o.offering_id = v.offering_id
JOIN academic_session sess ON sess.session_id = o.session_id
JOIN course c              ON c.course_code = o.course_code
JOIN department d          ON d.dept_id = c.dept_id
JOIN faculty f             ON f.faculty_id = d.faculty_id
WHERE sess.name = '2024/2025'
GROUP BY f.name
ORDER BY pass_rate_pct DESC;

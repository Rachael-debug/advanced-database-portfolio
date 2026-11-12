CREATE MATERIALIZED VIEW mv_result_summary AS
SELECT
  v.result_id,
  o.session_id,
  d.faculty_id,
  v.grade
FROM v_result_grade v
JOIN course_offering o ON o.offering_id = v.offering_id
JOIN course c          ON c.course_code = o.course_code
JOIN department d      ON d.dept_id = c.dept_id;

CREATE UNIQUE INDEX idx_mv_result_id ON mv_result_summary (result_id);
CREATE INDEX idx_mv_session ON mv_result_summary (session_id);
ANALYZE mv_result_summary;
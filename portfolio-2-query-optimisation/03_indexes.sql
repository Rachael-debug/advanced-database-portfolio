-- Q2: find all students in one course offering
CREATE INDEX idx_registration_offering ON registration (offering_id);

-- Q3: find all students in one programme
CREATE INDEX idx_student_programme ON student (programme_id);

ANALYZE;

SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename;
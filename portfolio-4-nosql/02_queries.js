// find a student by matric number
db.transcripts.findOne({matric_no: "LMU/2022/00002"});

// students who took CSC 101
db.transcripts.find(
  { "semesters.courses.course_code": "CSC 101" },
  { _id: 0, matric_no: 1, "name.first": 1 }
);

// students who took CSC 101 and scored an A
// wrong way
db.transcripts.find(
  { "semesters.courses.course_code": "CSC 101", "semesters.courses.grade": "A" },
  { _id: 0, matric_no: 1 }
)
// correct way
db.transcripts.find(
  { "semesters.courses": { $elemMatch: { course_code: "CSC 101", grade: "A" } } },
  { _id: 0, matric_no: 1 }
)

// students with scholarship

db.transcripts.find(
    {scholarship: {$exists: true}},
    { _id: 0, matric_no: 1, scholarship: 1 }
)

// students with CGPA of 3.5 or above, highest first
db.transcripts.find(
  { cgpa: { $gte: 3.5 } },
  { _id: 0, matric_no: 1, "name.first": 1, cgpa: 1 }
).sort({ cgpa: -1 })
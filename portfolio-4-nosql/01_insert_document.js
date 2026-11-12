db.transcripts.insertOne({
  matric_no: "LMU/2022/00002",
  name: { first: "Musa", last: "Ibrahim" },
  programme: "B.Sc. Computer Science",
  department: "Computer Science",
  faculty: "Faculty of Science",
  entry_year: 2022,
  semesters: [
    {
      session: "2022/2023",
      semester: 1,
      gpa: 4.2,
      courses: [
        { course_code: "CSC 101", title: "Introduction to Computing", units: 3, ca: 30, exam: 42, total: 72, grade: "A", grade_point: 5 },
        { course_code: "CSC 103", title: "Computer Science 100 Course 3", units: 2, ca: 22, exam: 36, total: 58, grade: "C", grade_point: 3 }
      ]
    },
    {
      session: "2022/2023",
      semester: 2,
      gpa: 4.0,
      courses: [
        { course_code: "CSC 102", title: "Computer Science 100 Course 2", units: 3, ca: 28, exam: 37, total: 65, grade: "B", grade_point: 4 }
      ]
    }
  ],
  cgpa: 4.13
});

db.transcripts.insertMany([
  {
    matric_no: "LMU/2022/00005",
    name: { first: "Tolu", last: "Adeyemi" },
    programme: "B.Sc. Computer Science",
    department: "Computer Science",
    faculty: "Faculty of Science",
    entry_year: 2022,
    scholarship: "Dean's List Award",
    semesters: [
      {
        session: "2022/2023",
        semester: 1,
        gpa: 3.8,
        courses: [
          { course_code: "CSC 101", title: "Introduction to Computing", units: 3, ca: 20, exam: 35, total: 55, grade: "C", grade_point: 3 },
          { course_code: "CSC 103", title: "Computer Science 100 Course 3", units: 2, ca: 32, exam: 42, total: 74, grade: "A", grade_point: 5 }
        ]
      }
    ],
    cgpa: 3.8
  },
  {
    matric_no: "LMU/2025/00006",
    name: { first: "Zainab", last: "Bello" },
    programme: "B.Sc. Accounting",
    department: "Accounting",
    faculty: "Faculty of Management Sciences",
    entry_year: 2025,
    hall_of_residence: "Moremi Hall",
    semesters: [],
    cgpa: null
  }
])
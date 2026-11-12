// ---------- Lists the generator picks from ----------
const depts = [
  { department: "Computer Science",       prefix: "CSC", faculty: "Faculty of Science" },
  { department: "Mathematics",            prefix: "MTH", faculty: "Faculty of Science" },
  { department: "Electrical Engineering", prefix: "EEE", faculty: "Faculty of Engineering" },
  { department: "Economics",              prefix: "ECO", faculty: "Faculty of Social Sciences" },
  { department: "Accounting",             prefix: "ACC", faculty: "Faculty of Management Sciences" },
  { department: "English",                prefix: "ENG", faculty: "Faculty of Arts" }
];
const firstNames = ["Tolu","Musa","Chioma","Ade","Fatima","Obinna","Zainab","Tunde","Ifeoma","Sani"];
const lastNames  = ["Adeyemi","Ibrahim","Okafor","Bello","Eze","Lawal","Okeke","Abubakar","Balogun","Nwosu"];

// ---------- Helper functions ----------
// A random whole number from min to max (inclusive)
function randInt(min, max) {
  return min + Math.floor(Math.random() * (max - min + 1));
}

// The 5-point grade scale, same as grade_scale in PostgreSQL
function gradeOf(total) {
  if (total >= 70) return ["A", 5];
  if (total >= 60) return ["B", 4];
  if (total >= 50) return ["C", 3];
  if (total >= 45) return ["D", 2];
  if (total >= 40) return ["E", 1];
  return ["F", 0];
}

// GPA = sum(units x grade point) / sum(units), rounded to 2 decimals
function gpaOf(courses) {
  let points = 0, units = 0;
  for (const c of courses) { points += c.units * c.grade_point; units += c.units; }
  return units === 0 ? null : Math.round((points / units) * 100) / 100;
}

// ---------- Build and insert 10,000 transcripts ----------
let batch = [];
for (let i = 101; i <= 10100; i++) {
  const d = depts[i % depts.length];
  // Use a different counter for entry year than for department (i % 6),
  // so every department has students from every entry year
  const entryYear = 2020 + (Math.floor(i / 6) % 6);
  const yearsCompleted = Math.min(2025 - entryYear, 4);   // published years only

  const semesters = [];
  const allCourses = [];
  for (let y = 0; y < yearsCompleted; y++) {
    const level = (y + 1) * 100;
    const session = (entryYear + y) + "/" + (entryYear + y + 1);
    for (let sem = 1; sem <= 2; sem++) {
      const courses = [];
      for (let k = sem; k <= 10; k += 2) {                  // odd numbers in sem 1, even in sem 2
        const ca = randInt(10, 40), exam = randInt(15, 60), total = ca + exam;
        const [grade, gp] = gradeOf(total);
        courses.push({
          course_code: d.prefix + " " + (level / 100) + String(k).padStart(2, "0"),
          title: d.department + " " + level + " Course " + k,
          units: randInt(2, 4), ca: ca, exam: exam, total: total,
          grade: grade, grade_point: gp
        });
      }
      semesters.push({ session: session, semester: sem, gpa: gpaOf(courses), courses: courses });
      allCourses.push(...courses);
    }
  }

  batch.push({
    matric_no: "LMU/" + entryYear + "/" + String(i).padStart(5, "0"),
    name: { first: firstNames[randInt(0, 9)], last: lastNames[randInt(0, 9)] },
    programme: "B.Sc. " + d.department,
    department: d.department,
    faculty: d.faculty,
    entry_year: entryYear,
    semesters: semesters,
    cgpa: gpaOf(allCourses)
  });

  // Send to the database 500 at a time
  if (batch.length === 500) {
    db.transcripts.insertMany(batch);
    print("Inserted up to student " + i);
    batch = [];
  }
}

print("Done. Total documents: " + db.transcripts.countDocuments());

// before indexing, find a student by matric number

const before = db.transcripts.find({ matric_no: "LMU/2021/05010" }).explain("executionStats");

printjson({
  stage: before.queryPlanner.winningPlan.stage,
  time_ms: before.executionStats.executionTimeMillis,
  docs_examined: before.executionStats.totalDocsExamined,
  keys_examined: before.executionStats.totalKeysExamined,
  returned: before.executionStats.nReturned
});

db.transcripts.createIndex({ matric_no: 1 }, { unique: true })

// after indexing, find a student by matric number
const after = db.transcripts.find({ matric_no: "LMU/2021/05010" }).explain("executionStats");

printjson({
  stage: after.queryPlanner.winningPlan.stage,
  time_ms: after.executionStats.executionTimeMillis,
  docs_examined: after.executionStats.totalDocsExamined,
  keys_examined: after.executionStats.totalKeysExamined,
  returned: after.executionStats.nReturned
});

// multikey index
const b2 = db.transcripts.find({ "semesters.courses.course_code": "CSC 201" }).explain("executionStats");
printjson({ stage: b2.queryPlanner.winningPlan.stage, docs_examined: b2.executionStats.totalDocsExamined, returned: b2.executionStats.nReturned });

db.transcripts.createIndex({ "semesters.courses.course_code": 1 })

const a2 = db.transcripts.find({ "semesters.courses.course_code": "CSC 201" }).explain("executionStats");
printjson({ stage: a2.queryPlanner.winningPlan.stage, docs_examined: a2.executionStats.totalDocsExamined, returned: a2.executionStats.nReturned });

// Reports with aggregation pipeline

// Report 1: Average CGPA by faculty
db.transcripts.aggregate([
  { $match: { cgpa: { $ne: null } } },
  { $group: {
      _id: "$faculty",
      students: { $sum: 1 },
      avg_cgpa: { $avg: "$cgpa" }
  } },
  { $sort: { avg_cgpa: -1 } }
])

// Report 2: Grade distribution for CSC 201 in 2024/2025
db.transcripts.aggregate([
  { $unwind: "$semesters" },
  { $unwind: "$semesters.courses" },
  { $match: {
      "semesters.session": "2024/2025",
      "semesters.courses.course_code": "CSC 201"
  } },
  { $group: { _id: "$semesters.courses.grade", students: { $sum: 1 } } },
  { $sort: { _id: 1 } }
])

// Renaming a department
db.transcripts.updateMany(
  { department: "Computer Science" },
  { $set: { department: "Computer Science and Informatics" } }
);
db.transcripts.updateMany(
  { department: "Computer Science and Informatics" },
  { $set: { department: "Computer Science" } }
);

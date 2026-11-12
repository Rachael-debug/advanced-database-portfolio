// asking the cluster about itself
db.hello();

// which server answered the query (read preference)
const fromPrimary = db.transcripts.find({ matric_no: "LMU/2021/05010" }).readPref("primary").explain();
print("Primary read served by:   " + fromPrimary.serverInfo.host);

const fromSecondary = db.transcripts.find({ matric_no: "LMU/2021/05010" }).readPref("secondary").explain();
print("Secondary read served by: " + fromSecondary.serverInfo.host);

// safe writes (write concern)
db.transcripts.insertOne(
  { matric_no: "TEST/REPLICATION/001", note: "write concern test" },
  { writeConcern: { w: "majority", wtimeout: 5000 } }
)

db.transcripts.find({ matric_no: "TEST/REPLICATION/001" }).readConcern("majority");

db.transcripts.deleteOne({ matric_no: "TEST/REPLICATION/001" });

// network latency
let start = Date.now();
db.transcripts.findOne({ matric_no: "LMU/2021/05010" });
print("Round trip: " + (Date.now() - start) + " ms");

// storage used
db.stats(1024 * 1024);
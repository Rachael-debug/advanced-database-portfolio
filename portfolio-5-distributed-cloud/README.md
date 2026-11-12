# Portfolio 5: Distributed and Cloud Database Exercise

**Case study:** Lagos Metropolitan University (LMU) Student Result Portal
**Platform:** MongoDB Atlas, free M0 cluster (a 3-member replica set managed in the cloud)

## What this portfolio covers

This folder examines what changes when a database runs on several servers in the cloud rather than on one local machine. It gathers evidence of replication, read preference, write concern and network latency from the Atlas cluster used in Portfolio 4, and discusses failover, sharding and the consistency/availability trade-off as they apply to the LMU portal.

## Files in this folder

| File | Purpose |
|---|---|
| `01_replication.js` | Commands for the replica set, read preference, write/read concern, latency and storage tests |
| `screenshots/` | Atlas cluster overview, metrics, and shell output |

## Key concepts

- **Replication** keeps identical copies of the data on several servers. Atlas runs a **replica set** of three members: one **primary**, which accepts all writes, and two **secondaries**, which copy the primary's changes. If the primary fails, the secondaries elect a new primary.
- **Sharding** splits data across servers, each holding a portion. Replication copies everything; sharding divides it.
- **Consistency vs availability:** a secondary may be slightly behind the primary. Each operation can choose between reading the latest data from the primary, or spreading load by reading possibly slightly older data from secondaries.

## Evidence

### 1. The cluster is a 3-member replica set

The Atlas cluster overview shows three members, one primary and two secondaries, on the free M0 tier. The Metrics tab shows a spike in operations when the 10,000 transcripts were inserted for Portfolio 4. Monitoring is included automatically with a managed cloud service.

`db.hello()` confirmed:

| Field | Value |
|---|---|
| setName | `atlas-7fngi9-shard-0` |
| hosts | 3 servers |
| primary | `ac-tlz65b5-shard-00-02.bputza2.mongodb.net:27017` |

The "shard-0" in the set name is Atlas's internal naming. The cluster is a single replica set, not a sharded cluster.

### 2. Read preference: reads can be served by a secondary

The same query was run with two read preferences, and `explain().serverInfo.host` showed which server answered:

| Read preference | Served by |
|---|---|
| `primary` | `ac-tlz65b5-shard-00-02` (the primary) |
| `secondary` | `ac-tlz65b5-shard-00-00` (a secondary) |

Sending reads to secondaries spreads load across all three servers. On result-release day, when thousands of students view transcripts at once, secondaries can serve those reads while the primary remains free for lecturers entering and approving scores.

### 3. Write concern and read concern

A test document was inserted with `{ writeConcern: { w: "majority", wtimeout: 5000 } }`, and the insert was acknowledged. With `w: "majority"`, the primary confirms the write only after at least 2 of the 3 members have it, so the write survives if the primary then fails. The document was read back with `readConcern("majority")`, which returns only data a majority has confirmed and that therefore cannot be rolled back by a failover. The test document was then deleted.

For the LMU portal, score entry and approval should use `w: "majority"`, so an approved result can never be lost. This extends the durability property from Portfolio 3 across multiple servers.

### 4. Network latency

| Measure | Time |
|---|---|
| Query execution on the server (`explain()`, Portfolio 4) | about 1 ms |
| Full round trip from Lagos (3 runs) | 194 ms, 288 ms, 192 ms |

More than 99% of the time was network travel between Lagos and the data centre, not query processing. In a cloud database, where the data is located can matter more than how efficient the query is. For a Nigerian university, a replica in or near Nigeria would improve response times far more than additional indexes. Atlas supports placing replica set members in several regions, so reads can be served by the closest copy.

### 5. Storage

| Measure | Size |
|---|---|
| dataSize (uncompressed) | 36 MB |
| storageSize (on disk) | 18 MB |
| Free tier limit | 512 MB |

MongoDB's WiredTiger storage engine compresses data on disk, halving the space used. Compression works well here because the document model repeats so much text, such as department names, course titles and field names. This partly offsets the storage cost of embedding. Storage limits that are paid to raise are a practical constraint of cloud databases.

## Failover (discussed, not tested)

The free M0 tier does not provide Atlas's primary failover test, which is available on paid dedicated clusters, so failover could not be triggered. Based on the replica set observed above, failover would work as follows:

1. If the primary (`-02`) becomes unavailable, the two secondaries (`-00` and `-01`) stop receiving its heartbeats.
2. They hold an **election**. Two of three members is a majority, so they can elect a new primary, typically within about 10–12 seconds.
3. Applications using the connection string automatically find the new primary, and modern drivers retry interrupted writes once.
4. Writes acknowledged with `w: "majority"` are guaranteed to exist on the new primary. A write acknowledged only by the old primary (`w: 1`) could be lost if it had not yet been copied.

A replica set needs a majority to elect a primary. If two of the three members failed, the remaining member could not become primary and would only serve reads. This is why replica sets use an odd number of members.

## Consistency vs availability

The CAP theorem states that when a network failure separates servers, a distributed system must choose between **consistency** (every read sees the latest write) and **availability** (every request receives a response). A MongoDB replica set favours consistency for writes: only a primary elected by a majority can accept writes, so servers on the minority side of a network split stop accepting them. For reads, the application can choose per operation.

| LMU operation | Choice | Reason |
|---|---|---|
| Lecturer enters or corrects scores | Write to primary, `w: "majority"` | A score must never be lost or contradicted |
| HOD approves results | Write to primary, `w: "majority"` | Approval must be durable before results are released |
| Student checks registration status | Read from primary | Must reflect a registration made moments ago |
| Student views published transcript | Read from secondary | Published results rarely change; a delay of under a second is harmless, and load is spread |
| Faculty pass-rate reports | Read from secondary | Analytical; slightly stale data is acceptable |

## Sharding design

The free tier does not support sharding, so this is a proposed design for when the transcripts collection outgrows one replica set: for example, decades of graduates, or several universities sharing the platform.

The most important decision is the **shard key**, the field that determines which shard holds each document.

| Candidate shard key | Assessment |
|---|---|
| `faculty` | **Rejected.** Only 5 values, so the data can never be split across more than 5 shards. Uneven: Science holds about twice as many students as other faculties. All requests for one faculty fall on one shard. |
| `entry_year` | **Rejected.** Values only increase, so every new student is written to the newest year's shard, creating a **hot shard**. The newest cohorts are also read the most. |
| hashed `matric_no` | **Chosen.** Hashing turns each matric number into an evenly spread value, so students are distributed evenly across shards. A transcript lookup by matric number goes to exactly one shard (a **targeted query**). |

**Trade-off:** queries that are not based on matric number, such as a course's grade distribution or a faculty pass rate, must be sent to every shard and their results combined (**scatter-gather**). This is acceptable because the collection's main purpose is serving individual transcripts, and reports can run on secondaries outside peak times.

## PostgreSQL in a distributed setting

PostgreSQL, the system of record from Portfolios 1–3, addresses the same problems differently:

- **Read replicas (streaming replication):** read-only copies of the primary database could serve transcript and report queries on result-release day, while score entry continues on the primary.
- **Table partitioning:** the registration and result tables could be partitioned by academic session, so queries for the current session read only the current partition, and older sessions can be archived to cheaper storage.
- **Managed cloud services:** PostgreSQL is available as a managed service from major cloud providers, offering the same benefits seen with Atlas: automated replication, backups and monitoring.

## Summary

| Concept | Evidence or design |
|---|---|
| Replication | 3-member replica set confirmed with `db.hello()` |
| Read scaling | Secondary read served by a different server (`-00`) from the primary (`-02`) |
| Durability across servers | Write acknowledged with `w: "majority"` |
| Cloud latency | 1 ms on the server vs ~190–290 ms round trip from Lagos |
| Storage | 36 MB of data compressed to 18 MB on disk |
| Failover | Majority election explained; not testable on the free tier |
| Sharding | Hashed matric_no chosen over faculty and entry_year |
| Consistency vs availability | Primary and majority for score entry; secondaries for published transcripts |

## Screenshots

| Evidence | File |
|---|---|
| Atlas cluster overview (3 members, M0, region) | `screenshots/01-cluster-overview.png` |
| Atlas metrics showing the insert spike | `screenshots/02-metrics.png` |
| `db.hello()` output | `screenshots/03-hello.png` |
| Primary vs secondary read | `screenshots/04-read-preference.png` |
| Write concern majority and read concern | `screenshots/05-write-concern.png` |
| Round-trip latency | `screenshots/06-latency.png` |
| `db.stats()` storage | `screenshots/07-storage.png` |

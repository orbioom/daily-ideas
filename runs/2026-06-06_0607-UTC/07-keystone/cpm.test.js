/*
 * cpm.test.js — Node verification harness for the pure CPM engine.
 *
 * Not shipped to the browser (index.html never loads it). Run it with:
 *     node cpm.test.js
 * It asserts the schedule on the seed project, a known hand-computable graph,
 * cycle detection, the "what-if" duration change, and edge cases. Exits non-zero
 * on any failed assertion.
 */

var CPM = require("./cpm.js");
var SEED = require("./seed.js");

var failures = 0;
function assert(cond, msg) {
  if (cond) {
    console.log("  ok  " + msg);
  } else {
    failures++;
    console.log("  FAIL " + msg);
  }
}

// --- 1. Seed project ---
console.log("Seed project (Mobile App v1 Launch):");
var seed = SEED.makeSampleProject();
var r = CPM.compute(seed.tasks);
assert(r.ok, "computes without a cycle");
var maxEf = Math.max.apply(
  null,
  Object.keys(r.tasks).map(function (id) {
    return r.tasks[id].ef;
  })
);
assert(r.projectDuration === 46, "project duration is 46 (got " + r.projectDuration + ")");
assert(r.projectDuration === maxEf, "duration equals max EF");
assert(
  r.criticalIds.every(function (id) {
    return r.tasks[id].slack === 0;
  }),
  "every critical task has zero slack"
);
assert(
  seed.tasks.every(function (t) {
    var n = r.tasks[t.id];
    return n.critical === (n.slack === 0);
  }),
  "critical flag matches zero-slack everywhere"
);
assert(
  seed.tasks.every(function (t) {
    var n = r.tasks[t.id];
    return n.ls >= n.es && n.lf >= n.ef && n.slack >= 0;
  }),
  "LS>=ES, LF>=EF, slack>=0 for all tasks"
);
assert(r.criticalPaths.length >= 1, "at least one critical path extracted");
assert(
  r.criticalPaths[0].join(",") === "t1,t2,t3,t5,t6,t8,t11,t12,t15",
  "critical path is t1>t2>t3>t5>t6>t8>t11>t12>t15"
);
console.log("  slack examples: t4=" + r.tasks.t4.slack + ", t9=" + r.tasks.t9.slack + ", t14=" + r.tasks.t14.slack);

// --- 2. Hand-computable graph ---
console.log("Hand graph A(3)->B(2)->D(4); A->C(5)->D:");
var g = [
  { id: "A", name: "A", duration: 3, predecessors: [] },
  { id: "B", name: "B", duration: 2, predecessors: ["A"] },
  { id: "C", name: "C", duration: 5, predecessors: ["A"] },
  { id: "D", name: "D", duration: 4, predecessors: ["B", "C"] },
];
var rg = CPM.compute(g);
// A:0-3, C:3-8 (crit), D:8-12. B:3-5 then must finish by LS_D=8 => LF=8, LS=6,
// slack = 6-3 = 3. Duration 12.
assert(rg.projectDuration === 12, "duration 12 (got " + rg.projectDuration + ")");
assert(rg.tasks.B.slack === 3, "B slack 3 (got " + rg.tasks.B.slack + ")");
assert(rg.tasks.C.slack === 0 && rg.tasks.C.critical, "C critical");
assert(rg.tasks.D.es === 8 && rg.tasks.D.ef === 12, "D ES=8 EF=12");

// --- 3. Cycle detection (no hang/crash) ---
console.log("Cycle X->Y->Z->X:");
var cyc = [
  { id: "X", name: "X", duration: 1, predecessors: ["Z"] },
  { id: "Y", name: "Y", duration: 1, predecessors: ["X"] },
  { id: "Z", name: "Z", duration: 1, predecessors: ["Y"] },
];
var rc = CPM.compute(cyc);
assert(rc.ok === false, "ok is false");
assert(Array.isArray(rc.cycle) && rc.cycle.length > 0, "cycle reported: " + JSON.stringify(rc.cycle));

// --- 4. What-if: bump a non-critical task past its slack ---
console.log("What-if: extend t9 (Payments, slack 9) by 10 days -> should become critical:");
var what = SEED.makeSampleProject();
what.tasks.forEach(function (t) {
  if (t.id === "t9") t.duration += 10; // 4 -> 14, slack was 9
});
var rw = CPM.compute(what.tasks);
assert(rw.projectDuration > 46, "project duration grew past 46 (got " + rw.projectDuration + ")");
assert(rw.tasks.t9.critical || rw.tasks.t9.slack < 9, "t9 slack consumed (slack now " + rw.tasks.t9.slack + ")");

// --- 5. Edge cases ---
console.log("Edge cases:");
var empty = CPM.compute([]);
assert(empty.ok && empty.projectDuration === 0, "empty project: duration 0, ok");
var single = CPM.compute([{ id: "s", name: "Solo", duration: 7, predecessors: [] }]);
assert(single.projectDuration === 7 && single.tasks.s.critical, "single task is critical, duration 7");
var dangling = CPM.compute([
  { id: "p", name: "P", duration: 2, predecessors: ["ghost"] },
]);
assert(dangling.ok && dangling.projectDuration === 2, "dangling predecessor ignored gracefully");

console.log("");
if (failures) {
  console.log(failures + " assertion(s) FAILED");
  process.exit(1);
} else {
  console.log("All assertions passed.");
}

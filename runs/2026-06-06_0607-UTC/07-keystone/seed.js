/*
 * seed.js — A realistic sample project for first-run / "Reset to sample".
 *
 * Scenario: planning and shipping the v1 launch of a mobile app.
 * ~15 tasks with real upstream/downstream dependencies forming a DAG.
 * Durations are in working days.
 */

(function (root) {
  "use strict";

  function makeSampleProject() {
    var now = Date.now();
    return {
      id: "sample-" + now,
      name: "Mobile App v1 Launch",
      unit: "days",
      createdAt: now,
      tasks: [
        { id: "t1", name: "Product discovery & scope", duration: 5, predecessors: [] },
        { id: "t2", name: "User research interviews", duration: 4, predecessors: ["t1"] },
        { id: "t3", name: "Define feature requirements", duration: 3, predecessors: ["t1", "t2"] },
        { id: "t4", name: "UX wireframes", duration: 4, predecessors: ["t3"] },
        { id: "t5", name: "Visual design system", duration: 6, predecessors: ["t3"] },
        { id: "t6", name: "High-fidelity UI mockups", duration: 5, predecessors: ["t4", "t5"] },
        { id: "t7", name: "Backend API & data model", duration: 8, predecessors: ["t3"] },
        { id: "t8", name: "Mobile app build", duration: 10, predecessors: ["t6", "t7"] },
        { id: "t9", name: "Payments integration", duration: 4, predecessors: ["t7"] },
        { id: "t10", name: "QA test plan", duration: 2, predecessors: ["t6"] },
        { id: "t11", name: "QA & bug fixing", duration: 6, predecessors: ["t8", "t9", "t10"] },
        { id: "t12", name: "Beta program", duration: 5, predecessors: ["t11"] },
        { id: "t13", name: "App store submission", duration: 3, predecessors: ["t11"] },
        { id: "t14", name: "Marketing & launch assets", duration: 7, predecessors: ["t6"] },
        { id: "t15", name: "Public launch", duration: 2, predecessors: ["t12", "t13", "t14"] },
      ],
    };
  }

  var SEED = { makeSampleProject: makeSampleProject };

  if (typeof module !== "undefined" && module.exports) {
    module.exports = SEED;
  } else {
    root.SEED = SEED;
  }
})(typeof self !== "undefined" ? self : this);

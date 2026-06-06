/*
 * cpm.js — The pure Critical Path Method engine.
 *
 * Pure, dependency-free. Usable in the browser (attaches to window.CPM)
 * and in Node (module.exports). No DOM, no storage, no side effects.
 *
 * Input:  an array of tasks: { id, name, duration, predecessors: [id, ...] }
 * Output: a schedule with ES/EF/LS/LF/slack/critical per task, the project
 *         duration, the critical path(s), and cycle detection.
 */

(function (root) {
  "use strict";

  /**
   * Detect cycles in the dependency graph using DFS with a recursion stack.
   * Returns the first cycle found as an ordered array of task ids, or null.
   */
  function findCycle(tasks) {
    var byId = {};
    tasks.forEach(function (t) {
      byId[t.id] = t;
    });

    var WHITE = 0,
      GRAY = 1,
      BLACK = 2;
    var color = {};
    tasks.forEach(function (t) {
      color[t.id] = WHITE;
    });

    var cyclePath = null;
    var stack = [];

    function visit(id) {
      if (cyclePath) return;
      color[id] = GRAY;
      stack.push(id);

      var task = byId[id];
      var preds = (task && task.predecessors) || [];
      for (var i = 0; i < preds.length; i++) {
        var p = preds[i];
        if (!byId[p]) continue; // dangling predecessor; ignored here
        if (color[p] === GRAY) {
          // Found a back-edge: extract the cycle from the stack.
          var startIdx = stack.indexOf(p);
          cyclePath = stack.slice(startIdx).concat([p]);
          return;
        }
        if (color[p] === WHITE) {
          visit(p);
          if (cyclePath) return;
        }
      }

      stack.pop();
      color[id] = BLACK;
    }

    for (var j = 0; j < tasks.length; j++) {
      if (color[tasks[j].id] === WHITE) {
        visit(tasks[j].id);
        if (cyclePath) break;
      }
    }
    return cyclePath;
  }

  /**
   * Topological sort (Kahn's algorithm) over the dependency graph.
   * Edges point predecessor -> successor. Returns an ordered list of ids,
   * or null if a cycle prevents a complete ordering.
   */
  function topoSort(tasks) {
    var byId = {};
    var indegree = {};
    var successors = {};
    tasks.forEach(function (t) {
      byId[t.id] = t;
      indegree[t.id] = 0;
      successors[t.id] = [];
    });

    tasks.forEach(function (t) {
      (t.predecessors || []).forEach(function (p) {
        if (byId[p]) {
          successors[p].push(t.id);
          indegree[t.id] += 1;
        }
      });
    });

    var queue = [];
    tasks.forEach(function (t) {
      if (indegree[t.id] === 0) queue.push(t.id);
    });

    var order = [];
    while (queue.length) {
      var id = queue.shift();
      order.push(id);
      successors[id].forEach(function (s) {
        indegree[s] -= 1;
        if (indegree[s] === 0) queue.push(s);
      });
    }

    if (order.length !== tasks.length) return null; // cycle present
    return order;
  }

  /**
   * Compute the full CPM schedule.
   *
   * Returns:
   * {
   *   ok: boolean,
   *   cycle: [id,...] | null,
   *   tasks: { [id]: { id, name, duration, es, ef, ls, lf, slack, critical } },
   *   order: [id,...],
   *   projectDuration: number,
   *   criticalIds: [id,...],
   *   criticalPaths: [[id,...], ...]
   * }
   */
  function compute(rawTasks) {
    var tasks = (rawTasks || []).map(function (t) {
      return {
        id: t.id,
        name: t.name,
        duration: Math.max(0, Number(t.duration) || 0),
        predecessors: (t.predecessors || []).slice(),
      };
    });

    var byId = {};
    tasks.forEach(function (t) {
      byId[t.id] = t;
    });

    // Drop dangling predecessor references (referencing a deleted task).
    tasks.forEach(function (t) {
      t.predecessors = t.predecessors.filter(function (p) {
        return !!byId[p];
      });
    });

    if (tasks.length === 0) {
      return {
        ok: true,
        cycle: null,
        tasks: {},
        order: [],
        projectDuration: 0,
        criticalIds: [],
        criticalPaths: [],
      };
    }

    var order = topoSort(tasks);
    if (order === null) {
      var cycle = findCycle(tasks);
      return {
        ok: false,
        cycle: cycle,
        tasks: {},
        order: [],
        projectDuration: 0,
        criticalIds: [],
        criticalPaths: [],
      };
    }

    // Build successor map for the backward pass.
    var successors = {};
    tasks.forEach(function (t) {
      successors[t.id] = [];
    });
    tasks.forEach(function (t) {
      t.predecessors.forEach(function (p) {
        successors[p].push(t.id);
      });
    });

    var node = {};
    tasks.forEach(function (t) {
      node[t.id] = {
        id: t.id,
        name: t.name,
        duration: t.duration,
        es: 0,
        ef: 0,
        ls: 0,
        lf: 0,
        slack: 0,
        critical: false,
      };
    });

    // Forward pass: ES = max(EF of predecessors), EF = ES + duration.
    order.forEach(function (id) {
      var t = byId[id];
      var es = 0;
      t.predecessors.forEach(function (p) {
        if (node[p].ef > es) es = node[p].ef;
      });
      node[id].es = es;
      node[id].ef = es + t.duration;
    });

    // Project duration = max EF across all tasks.
    var projectDuration = 0;
    order.forEach(function (id) {
      if (node[id].ef > projectDuration) projectDuration = node[id].ef;
    });

    // Backward pass: LF = min(LS of successors) (or projectDuration for
    // terminal tasks), LS = LF - duration. Process in reverse topo order.
    var reverse = order.slice().reverse();
    reverse.forEach(function (id) {
      var succs = successors[id];
      var lf;
      if (succs.length === 0) {
        lf = projectDuration;
      } else {
        lf = Infinity;
        succs.forEach(function (s) {
          if (node[s].ls < lf) lf = node[s].ls;
        });
      }
      node[id].lf = lf;
      node[id].ls = lf - node[id].duration;
      node[id].slack = node[id].ls - node[id].es;
      // Guard against floating-point dust before the zero comparison.
      if (Math.abs(node[id].slack) < 1e-9) node[id].slack = 0;
      node[id].critical = node[id].slack === 0;
    });

    var criticalIds = order.filter(function (id) {
      return node[id].critical;
    });

    var criticalPaths = extractCriticalPaths(
      order,
      byId,
      successors,
      node,
      projectDuration
    );

    return {
      ok: true,
      cycle: null,
      tasks: node,
      order: order,
      projectDuration: projectDuration,
      criticalIds: criticalIds,
      criticalPaths: criticalPaths,
    };
  }

  /**
   * Extract every critical path: chains of critical tasks where each
   * successor starts exactly when its predecessor finishes (EF === ES),
   * beginning at a critical task with no critical predecessor (ES === 0)
   * and ending at a critical task that finishes at the project end.
   */
  function extractCriticalPaths(order, byId, successors, node, projectDuration) {
    function isCritical(id) {
      return node[id].critical;
    }

    // Critical starts: critical tasks whose ES is 0 (no critical predecessor
    // constrains them earlier) — i.e. the chain origins.
    var starts = order.filter(function (id) {
      if (!isCritical(id)) return false;
      return node[id].es === 0;
    });

    var paths = [];

    function walk(id, path) {
      var nextPath = path.concat([id]);
      // Critical successors that continue the zero-slack chain seamlessly
      // (the successor starts exactly when this task finishes).
      var criticalSuccs = successors[id].filter(function (s) {
        return isCritical(s) && node[s].es === node[id].ef;
      });
      if (criticalSuccs.length === 0) {
        // End of a chain: record it only if it actually reaches project end.
        if (node[id].ef === projectDuration) paths.push(nextPath);
        return;
      }
      criticalSuccs.forEach(function (s) {
        walk(s, nextPath);
      });
    }

    starts.forEach(function (s) {
      walk(s, []);
    });

    // Deduplicate identical paths.
    var seen = {};
    var unique = [];
    paths.forEach(function (p) {
      var key = p.join(">");
      if (!seen[key]) {
        seen[key] = true;
        unique.push(p);
      }
    });
    return unique;
  }

  var CPM = {
    compute: compute,
    topoSort: topoSort,
    findCycle: findCycle,
  };

  if (typeof module !== "undefined" && module.exports) {
    module.exports = CPM;
  } else {
    root.CPM = CPM;
  }
})(typeof self !== "undefined" ? self : this);

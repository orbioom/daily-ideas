// Cadence cron engine — standard 5-field cron (min hour dom month dow).
// Supports  *  a  a,b  a-b  */n  a-b/n  and named months/days.
// Exported on window for the page; also usable under Node for tests.

(function (root) {
  const MONTHS = ["jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"];
  const DAYS = ["sun","mon","tue","wed","thu","fri","sat"];
  const NAMES = ["minute","hour","day of month","month","day of week"];
  const RANGES = [[0,59],[0,23],[1,31],[1,12],[0,6]];

  function parseField(spec, idx) {
    const [lo, hi] = RANGES[idx];
    spec = spec.toLowerCase();
    if (idx === 3) MONTHS.forEach((m,i)=>spec=spec.replace(new RegExp(m,"g"),i+1));
    if (idx === 4) DAYS.forEach((d,i)=>spec=spec.replace(new RegExp(d,"g"),i));
    const set = new Set();
    for (const part of spec.split(",")) {
      let step = 1, body = part;
      if (part.includes("/")) { const [b,s] = part.split("/"); body=b; step=parseInt(s,10);
        if(!step||step<1) throw new Error(`bad step in "${part}"`); }
      let a = lo, b = hi;
      if (body === "*") { /* full */ }
      else if (body.includes("-")) { const [x,y]=body.split("-"); a=+x; b=+y; }
      else { a = b = +body; }
      if (Number.isNaN(a)||Number.isNaN(b)) throw new Error(`bad ${NAMES[idx]} "${part}"`);
      if (a<lo||b>hi||a>b) throw new Error(`${NAMES[idx]} out of range in "${part}" (${lo}-${hi})`);
      for (let v=a; v<=b; v+=step) set.add(v);
    }
    return set;
  }

  function parse(expr) {
    const parts = expr.trim().split(/\s+/);
    if (parts.length !== 5) throw new Error("need exactly 5 fields: min hour dom month dow");
    return parts.map(parseField);
  }

  // next run strictly after `from` (Date). dom/dow: if both restricted, cron
  // uses OR semantics (match either); if one is "*", only the other applies.
  function next(sets, from) {
    const [min,hr,dom,mon,dow] = sets;
    const domAll = dom.size === 31, dowAll = dow.size === 7;
    let d = new Date(from.getTime());
    d.setSeconds(0,0);
    d.setMinutes(d.getMinutes()+1);
    for (let guard=0; guard<525960; guard++) { // up to ~1 year of minutes
      if (!mon.has(d.getMonth()+1)) { d.setMonth(d.getMonth()+1,1); d.setHours(0,0,0,0); continue; }
      const domOk = dom.has(d.getDate()), dowOk = dow.has(d.getDay());
      const dayOk = (domAll && dowAll) ? true
                  : (domAll ? dowOk : dowAll ? domOk : (domOk || dowOk));
      if (!dayOk) { d.setDate(d.getDate()+1); d.setHours(0,0,0,0); continue; }
      if (!hr.has(d.getHours())) { d.setHours(d.getHours()+1,0,0,0); continue; }
      if (!min.has(d.getMinutes())) { d.setMinutes(d.getMinutes()+1,0,0); continue; }
      return new Date(d.getTime());
    }
    return null;
  }

  function nextN(expr, n, from) {
    const sets = parse(expr);
    const out = []; let cur = from || new Date();
    for (let i=0;i<n;i++){ const nx = next(sets, cur); if(!nx) break; out.push(nx); cur = nx; }
    return out;
  }

  // Human-readable English description.
  function describe(expr) {
    const sets = parse(expr);
    const [min,hr,dom,mon,dow] = sets;
    const list=(s,names)=>[...s].sort((a,b)=>a-b).map(v=>names?names[v]:v);
    const everyMin = min.size===60, everyHr = hr.size===24;
    let t;
    if (everyMin && everyHr) t="every minute";
    else if (everyMin) t=`every minute during hour(s) ${list(hr).join(", ")}`;
    else if (min.size===1 && hr.size===1)
      t=`at ${String([...hr][0]).padStart(2,"0")}:${String([...min][0]).padStart(2,"0")}`;
    else if (everyHr) t=`at minute(s) ${list(min).join(", ")} past every hour`;
    else t=`at minute(s) ${list(min).join(", ")} of hour(s) ${list(hr).join(", ")}`;
    const dParts=[];
    if (dom.size!==31) dParts.push(`on day-of-month ${list(dom).join(", ")}`);
    if (dow.size!==7) dParts.push(`on ${list(dow,["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]).join(", ")}`);
    if (mon.size!==12) dParts.push(`in ${list(mon,["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]).join(", ")}`);
    return (t + (dParts.length? " "+dParts.join(" "):"")).replace(/^./,c=>c.toUpperCase());
  }

  root.Cadence = { parse, nextN, describe };
})(typeof window !== "undefined" ? window : globalThis);

if (typeof module !== "undefined") module.exports = (typeof window!=="undefined"?window:globalThis).Cadence;

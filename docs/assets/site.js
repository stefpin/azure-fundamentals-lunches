/* =============================================================================
   Azure Fundamentals: One Lunch at a Time — site behaviour
   Progress, XP, badges and notes are stored only in this browser (localStorage).
   ============================================================================= */
(function () {
  'use strict';

  var C = window.COURSE || { lunches: [], parts: [], levels: [], specialBadges: [] };
  var doc = document, root = doc.documentElement, body = doc.body;
  var ROOT = body.getAttribute('data-root') || '';
  var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var $ = function (s, el) { return (el || doc).querySelector(s); };
  var $$ = function (s, el) { return Array.prototype.slice.call((el || doc).querySelectorAll(s)); };
  var byN = {}; C.lunches.forEach(function (l) { byN[l.n] = l; });
  var partOf = {}; (C.parts || []).forEach(function (p) { partOf[p.id] = p; });

  /* ------------------------------------------------------------------ store */
  var KEY = 'azlunch.v1';
  var S = load();
  function blank() { return { done: {}, quiz: {}, obj: {}, notes: [], labs: {}, demo: {}, think: {}, timer: {}, name: '' }; }
  function load() {
    try { var s = JSON.parse(localStorage.getItem(KEY) || 'null'); if (s && typeof s === 'object') { var b = blank(); for (var k in b) { if (!(k in s)) s[k] = b[k]; } return s; } } catch (e) { /* ignore */ }
    return blank();
  }
  function save() { try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) { /* private mode */ } updateHud(); }
  function lab(n) { if (!S.labs[n]) S.labs[n] = { tasks: {} }; if (!S.labs[n].tasks) S.labs[n].tasks = {}; return S.labs[n]; }

  /* ----------------------------------------------------------- calculations */
  function doneCount(range) {
    return C.lunches.filter(function (l) { var x = +l.n; return S.done[l.n] && (!range || (x >= range[0] && x <= range[1])); }).length;
  }
  function quizCorrect() { var c = 0; Object.keys(S.quiz).forEach(function (n) { var q = S.quiz[n]; Object.keys(q).forEach(function (k) { if (q[k] === 1) c++; }); }); return c; }
  function quizGraded() { var c = 0; Object.keys(S.quiz).forEach(function (n) { c += Object.keys(S.quiz[n]).length; }); return c; }
  function labsDone() { return Object.keys(S.labs).filter(function (n) { return S.labs[n].done; }).length; }
  function labsCleaned() { return Object.keys(S.labs).filter(function (n) { return S.labs[n].cleaned; }).length; }
  function tasksDone() { var c = 0; Object.keys(S.labs).forEach(function (n) { c += Object.keys(S.labs[n].tasks || {}).length; }); return c; }
  function count(obj) { var c = 0; Object.keys(obj || {}).forEach(function (k) { var v = obj[k]; c += (typeof v === 'object' && v) ? Object.keys(v).filter(function (x) { return v[x]; }).length : (v ? 1 : 0); }); return c; }
  function xp() {
    return doneCount() * 100 + quizCorrect() * 20 + count(S.obj) * 5 + S.notes.length * 5 + count(S.think) * 5 +
      Object.keys(S.demo).length * 30 + tasksDone() * 15 + labsDone() * 150 + labsCleaned() * 25;
  }
  function level(x) {
    var lv = C.levels[0], next = null;
    for (var i = 0; i < C.levels.length; i++) { if (x >= C.levels[i].xp) { lv = C.levels[i]; next = C.levels[i + 1] || null; } }
    return { name: lv.name, at: lv.xp, next: next, idx: C.levels.indexOf(lv) };
  }
  function readiness() {
    var best = null;
    C.lunches.forEach(function (l) { if (S.done[l.n] && (!best || l.readiness > best.readiness)) best = l; });
    return best ? { pct: best.readiness, answer: best.answer, lunch: best } : { pct: 0, answer: (C.director || {}).start || '', lunch: null };
  }
  function nextLunch() { for (var i = 0; i < C.lunches.length; i++) { if (!S.done[C.lunches[i].n]) return C.lunches[i]; } return null; }
  function dayKey(ts) { var d = new Date(ts); return d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate(); }
  function streak() {
    var days = {}; Object.keys(S.done).forEach(function (n) { if (S.done[n]) days[dayKey(S.done[n])] = 1; });
    var d = new Date(), s = 0;
    for (var i = 0; i < 400; i++) {
      var wd = d.getDay(), k = dayKey(d.getTime());
      if (wd === 0 || wd === 6) { if (days[k]) s++; }          // weekends never break a streak
      else if (days[k]) s++;
      else if (i > 0) break;                                    // today may still be ahead of you
      d.setDate(d.getDate() - 1);
    }
    return s;
  }
  function badgeList() {
    var list = C.lunches.map(function (l) {
      return { id: 'l' + l.n, icon: l.badge.icon, name: l.badge.name, desc: l.badge.desc, got: S.done[l.n] || 0, n: l.n };
    });
    if (C.finale) list.push({ id: 'finale', icon: C.finale.badge.icon, name: C.finale.badge.name, desc: C.finale.badge.desc, got: (S.labs['32'] || {}).done || 0 });
    var perfect = Object.keys(S.quiz).some(function (n) { var q = S.quiz[n]; return Object.keys(q).filter(function (k) { return q[k] === 1; }).length >= 5; });
    var rules = {
      'first-bite': doneCount() >= 1, 'five-lunches': doneCount() >= 5, 'sharpshooter': perfect,
      'hands-on': labsDone() >= 5, 'clean-plate': labsCleaned() >= 3, 'season-1': doneCount([1, 21]) >= 21,
      'season-2': doneCount([22, 31]) >= 10, 'legend': doneCount() >= 31
    };
    (C.specialBadges || []).forEach(function (b) { list.push({ id: b.id, icon: b.icon, name: b.name, desc: b.desc, got: rules[b.id] ? 1 : 0, special: true }); });
    return list;
  }

  /* --------------------------------------------------------------- helpers */
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
  function lunchUrl(l) { return ROOT + 'lunches/' + l.slug + '.html'; }
  function labUrl(slug) { return ROOT + 'labs/' + slug + '.html'; }
  function moodFor(pct) { return pct < 10 ? 0 : pct < 35 ? 1 : pct < 60 ? 2 : pct < 90 ? 3 : 4; }
  function setMood(el, pct) { if (!el) return; el.classList.remove('mood-0', 'mood-1', 'mood-2', 'mood-3', 'mood-4'); el.classList.add('mood-' + moodFor(pct)); }

  /* ----------------------------------------------------------------- toasts */
  var stack;
  function toast(html, ms) {
    if (!stack) { stack = doc.createElement('div'); stack.className = 'toast-stack'; stack.setAttribute('role', 'status'); stack.setAttribute('aria-live', 'polite'); body.appendChild(stack); }
    var t = doc.createElement('div'); t.className = 'toast'; t.innerHTML = html; stack.appendChild(t);
    setTimeout(function () { t.style.transition = 'opacity .3s'; t.style.opacity = '0'; setTimeout(function () { t.remove(); }, 320); }, ms || 2600);
  }
  function xpToast(points, what) { toast('<span class="x">+' + points + ' XP</span> ' + esc(what)); }

  /* --------------------------------------------------------------- confetti */
  function confetti(amount) {
    if (reduceMotion) return;
    var cv = doc.getElementById('confetti');
    if (!cv) { cv = doc.createElement('canvas'); cv.id = 'confetti'; body.appendChild(cv); }
    var ctx = cv.getContext('2d'), W = cv.width = innerWidth, H = cv.height = innerHeight;
    var colors = ['#1665d8', '#7b4ff0', '#e2482f', '#f2a007', '#11935a', '#4aa3ff'];
    var parts = [];
    for (var i = 0; i < (amount || 160); i++) {
      parts.push({ x: W / 2 + (Math.random() - .5) * W * .3, y: H * .35, vx: (Math.random() - .5) * 14, vy: -Math.random() * 14 - 4,
        r: Math.random() * 6 + 4, c: colors[i % colors.length], a: Math.random() * Math.PI, va: (Math.random() - .5) * .3 });
    }
    var t0 = performance.now();
    (function frame(t) {
      ctx.clearRect(0, 0, W, H);
      parts.forEach(function (p) { p.vy += .35; p.vx *= .99; p.x += p.vx; p.y += p.vy; p.a += p.va;
        ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.a); ctx.fillStyle = p.c; ctx.fillRect(-p.r / 2, -p.r / 4, p.r, p.r / 2); ctx.restore(); });
      if (t - t0 < 3200) requestAnimationFrame(frame); else ctx.clearRect(0, 0, W, H);
    })(t0);
  }

  /* ------------------------------------------------------------- HUD / nav */
  function updateHud() {
    var pct = Math.round(doneCount() / Math.max(1, C.lunches.length) * 100);
    $$('[data-hud-ring]').forEach(function (r) { r.style.setProperty('--p', pct); });
    var x = xp(), lv = level(x);
    $$('[data-hud-text]').forEach(function (t) { t.textContent = x + ' XP · ' + lv.name; });
    $$('[data-hud-title]').forEach(function (t) { t.setAttribute('title', doneCount() + ' of ' + C.lunches.length + ' lunches · ' + x + ' XP · ' + lv.name); });
  }
  var mt = $('[data-menu-toggle]');
  if (mt) mt.addEventListener('click', function () { var nl = $('.nav-links'); var open = nl.classList.toggle('open'); mt.setAttribute('aria-expanded', open ? 'true' : 'false'); });
  $$('[data-theme-toggle]').forEach(function (b) {
    b.addEventListener('click', function () {
      var dark = root.getAttribute('data-theme') !== 'dark';
      root.setAttribute('data-theme', dark ? 'dark' : 'light');
      try { localStorage.setItem('azlunch.theme', dark ? 'dark' : 'light'); } catch (e) { /* ignore */ }
      b.textContent = dark ? '☀️' : '🌙';
      rerenderMermaid();
    });
    b.textContent = root.getAttribute('data-theme') === 'dark' ? '☀️' : '🌙';
  });

  /* -------------------------------------------------- reveal & read progress */
  if ('IntersectionObserver' in window && !reduceMotion) {
    var io = new IntersectionObserver(function (es) { es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } }); }, { rootMargin: '0px 0px -8% 0px' });
    $$('.reveal').forEach(function (el) { io.observe(el); });
  } else { $$('.reveal').forEach(function (el) { el.classList.add('in'); }); }
  var rp = $('.read-progress span');
  if (rp) {
    var onScroll = function () { var h = doc.documentElement.scrollHeight - innerHeight; rp.style.inlineSize = (h > 0 ? Math.min(100, scrollY / h * 100) : 0) + '%'; };
    addEventListener('scroll', onScroll, { passive: true }); onScroll();
  }

  /* -------------------------------------------------------- code & copying */
  var LANG = {
    bash: { r: [['#(?![{!])[^\\n]*', 'c'], ['"(?:\\\\.|[^"\\\\])*"', 's'], ["'[^']*'", 's'], ['\\$\\{[^}\\n]+\\}|\\$\\(|\\$[A-Za-z_][A-Za-z0-9_]*', 'v'],
      ['(?:^|(?<=\\s))--?[A-Za-z][\\w-]*', 'f'], ['\\b(?:if|then|else|elif|fi|for|in|do|done|while|until|case|esac|function|return|export|source|local|set|echo|printf|read|exit)\\b', 'k'],
      ['\\b(?:az|kubectl|git|curl|bash|sudo|cd|azcopy|sqlcmd|python3|pip|nslookup|dig|ssh|cat|grep|jq|openssl)\\b', 'p']] },
    json: { r: [['"(?:\\\\.|[^"\\\\])*"(?=\\s*:)', 'f'], ['"(?:\\\\.|[^"\\\\])*"', 's'], ['\\b(?:true|false|null)\\b', 'k'], ['-?\\b\\d+(?:\\.\\d+)?\\b', 'n']] },
    yaml: { r: [['#[^\\n]*', 'c'], ['^\\s*-?\\s*[\\w.\\-/]+(?=\\s*:)', 'f'], ['"(?:\\\\.|[^"\\\\])*"', 's'], ["'[^']*'", 's'], ['\\b(?:true|false|null|yes|no)\\b', 'k'], ['\\b\\d+(?:\\.\\d+)?\\b', 'n']] },
    bicep: { r: [['//[^\\n]*', 'c'], ['/\\*[\\s\\S]*?\\*/', 'c'], ["'(?:\\\\.|[^'\\\\])*'", 's'], ['@\\w+', 'v'],
      ['\\b(?:param|var|resource|module|output|targetScope|for|in|if|existing|import|type|func|metadata)\\b', 'k'], ['\\b(?:true|false|null)\\b', 'p'], ['\\b\\d+\\b', 'n']] },
    kql: { r: [['//[^\\n]*', 'c'], ['"(?:\\\\.|[^"\\\\])*"', 's'], ["'[^']*'", 's'],
      ['\\b(?:where|project|summarize|by|extend|order|sort|take|limit|render|join|kind|on|let|union|distinct|top|as|and|or|not|contains|has|in|between|asc|desc|parse|mv-expand|project-away)\\b', 'k'],
      ['\\b(?:ago|bin|count|countif|avg|sum|max|min|percentile|dcount|now|todatetime|tostring|toint|strcat|iff|isnotempty|isempty|arg_max|make_list|timechart|barchart|piechart)\\b', 'p'], ['\\b\\d+(?:\\.\\d+)?[a-z]*\\b', 'n']] },
    sql: { ci: true, r: [['--[^\\n]*', 'c'], ["N?'(?:''|[^'])*'", 's'],
      ['\\b(?:select|from|where|insert|into|values|create|table|alter|add|drop|update|set|delete|with|function|grant|user|execute|as|order|by|top|go|primary|key|identity|not|null|default|int|nvarchar|varchar|decimal|datetime2|masked|join|on|group|count|and|or|revert|login|without|schema|exists|if|begin|end)\\b', 'k'], ['\\b\\d+\\b', 'n']] },
    python: { r: [['#[^\\n]*', 'c'], ['"""[\\s\\S]*?"""', 's'], ['"(?:\\\\.|[^"\\\\])*"', 's'], ["'(?:\\\\.|[^'\\\\])*'", 's'], ['@\\w+', 'v'],
      ['\\b(?:def|return|if|elif|else|for|in|import|from|as|with|try|except|raise|class|while|and|or|not|None|True|False|async|await|lambda|pass)\\b', 'k'], ['\\b\\d+(?:\\.\\d+)?\\b', 'n']] },
    plain: { r: [['#[^\\n]*', 'c'], ['"(?:\\\\.|[^"\\\\])*"', 's']] }
  };
  LANG.sh = LANG.shell = LANG.console = LANG.powershell = LANG.ps1 = LANG.bash;
  LANG.yml = LANG.yaml; LANG.kusto = LANG.kql; LANG.tsql = LANG.sql; LANG.py = LANG.python; LANG.jsonc = LANG.json;
  function highlight(code, lang) {
    var def = LANG[lang] || null;
    if (!def) return esc(code);
    var re;
    try { re = new RegExp(def.r.map(function (r) { return '(' + r[0] + ')'; }).join('|'), 'gm' + (def.ci ? 'i' : '')); } catch (e) { return esc(code); }
    var out = '', last = 0, m;
    while ((m = re.exec(code))) {
      if (m[0] === '') { re.lastIndex++; continue; }
      var gi = 1; while (gi < m.length && m[gi] === undefined) gi++;
      out += esc(code.slice(last, m.index)) + '<span class="tok-' + def.r[gi - 1][1] + '">' + esc(m[0]) + '</span>';
      last = m.index + m[0].length;
    }
    return out + esc(code.slice(last));
  }
  $$('.code').forEach(function (box) {
    var codeEl = $('code', box), lang = (box.getAttribute('data-lang') || '').toLowerCase();
    var raw = codeEl.textContent;
    codeEl.innerHTML = highlight(raw, lang);
    var btn = $('.copy-btn', box);
    if (btn) btn.addEventListener('click', function () {
      var done = function () { btn.textContent = 'Copied ✓'; btn.classList.add('copied'); setTimeout(function () { btn.textContent = 'Copy'; btn.classList.remove('copied'); }, 1600); };
      if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(raw).then(done, function () { fallbackCopy(raw); done(); });
      else { fallbackCopy(raw); done(); }
    });
  });
  function fallbackCopy(t) { var ta = doc.createElement('textarea'); ta.value = t; ta.style.position = 'fixed'; ta.style.opacity = '0'; body.appendChild(ta); ta.select(); try { doc.execCommand('copy'); } catch (e) { /* ignore */ } ta.remove(); }

  /* --------------------------------------------------------------- mermaid */
  var MERMAID = 'https://cdn.jsdelivr.net/npm/mermaid@11.11.0/dist/mermaid.esm.min.mjs';
  var mermaidLib = null;
  $$('pre.mermaid').forEach(function (p) { p.setAttribute('data-src', p.textContent); });
  function mermaidTheme() {
    var dark = root.getAttribute('data-theme') === 'dark';
    return {
      startOnLoad: false, securityLevel: 'strict', theme: 'base', fontFamily: 'Plus Jakarta Sans, system-ui, sans-serif',
      flowchart: { curve: 'basis', htmlLabels: true }, themeVariables: dark ? {
        darkMode: true, background: '#172139', primaryColor: '#1d2c4d', primaryBorderColor: '#5aa8ff', primaryTextColor: '#ecf1fb',
        secondaryColor: '#33280f', tertiaryColor: '#12301f', lineColor: '#94a0ba', textColor: '#ecf1fb', clusterBkg: '#131c31', clusterBorder: '#2f3d61',
        edgeLabelBackground: '#131c31', noteBkgColor: '#33280f', noteTextColor: '#ecf1fb', fontSize: '15px'
      } : {
        background: '#fdfaf6', primaryColor: '#e6f0ff', primaryBorderColor: '#1665d8', primaryTextColor: '#16203a',
        secondaryColor: '#fff2d4', tertiaryColor: '#ddf4e8', lineColor: '#68738c', textColor: '#16203a', clusterBkg: '#fbf7f1', clusterBorder: '#ddd0bd',
        edgeLabelBackground: '#ffffff', noteBkgColor: '#fff2d4', noteTextColor: '#16203a', fontSize: '15px'
      }
    };
  }
  function runMermaid() {
    var nodes = $$('pre.mermaid'); if (!nodes.length) return;
    var go = function (m) {
      mermaidLib = m; m.initialize(mermaidTheme());
      m.run({ nodes: nodes }).catch(function () { nodes.forEach(function (n) { if (!n.querySelector('svg')) n.classList.add('mermaid-failed'); }); });
    };
    if (mermaidLib) { go(mermaidLib); return; }
    import(MERMAID).then(function (mod) { go(mod.default); }).catch(function () {
      nodes.forEach(function (n) { n.classList.add('mermaid-failed'); var c = n.closest('figure'); if (c && !$('figcaption', c)) { var f = doc.createElement('figcaption'); f.textContent = 'Diagram source (the diagram renderer could not be loaded).'; c.appendChild(f); } });
    });
  }
  function rerenderMermaid() {
    if (!mermaidLib) return;
    $$('pre.mermaid').forEach(function (p) { p.removeAttribute('data-processed'); p.textContent = p.getAttribute('data-src'); });
    runMermaid();
  }
  runMermaid();

  /* --------------------------------------------------------------- modals */
  function openModal(html) {
    var m = $('#modal');
    if (!m) { m = doc.createElement('div'); m.id = 'modal'; m.className = 'modal'; m.setAttribute('role', 'dialog'); m.setAttribute('aria-modal', 'true'); body.appendChild(m); }
    m.innerHTML = '<div class="modal-card">' + html + '<button class="btn btn-sm close" data-close aria-label="Close">✕</button></div>';
    m.classList.add('open');
    var close = function () { m.classList.remove('open'); doc.removeEventListener('keydown', onKey); };
    var onKey = function (e) { if (e.key === 'Escape') close(); };
    doc.addEventListener('keydown', onKey);
    m.onclick = function (e) { if (e.target === m || e.target.closest('[data-close]')) close(); };
    var f = $('.modal-card a, .modal-card button', m); if (f) f.focus();
    return m;
  }
  $$('figure.diagram .zoom-btn').forEach(function (b) {
    b.addEventListener('click', function () {
      var svg = $('svg', b.closest('figure')); if (!svg) return;
      var m = openModal('<div style="overflow:auto;max-height:78vh">' + svg.outerHTML + '</div>');
      var card = $('.modal-card', m); card.style.maxInlineSize = 'min(1200px, 96vw)';
      var s = $('svg', card); s.style.maxWidth = 'none'; s.style.width = '100%'; s.style.height = 'auto';
    });
  });

  /* ======================================================= LANDING PAGE */
  // typewriter bubble
  var bubble = $('[data-typed]');
  if (bubble) {
    var who = $('[data-who]');
    var rd = readiness();
    var lines = [
      { who: 'Ibu Sari · The director', text: (C.director || {}).question || '' },
      { who: 'You · ' + (rd.lunch ? 'after Episode ' + rd.lunch.n : 'on day one'), text: rd.answer }
    ];
    if (reduceMotion) { who.textContent = lines[1].who; bubble.textContent = lines[1].text; }
    else {
      var li = 0;
      var typeLine = function () {
        var L = lines[li % lines.length], i = 0; who.textContent = L.who; bubble.textContent = '';
        var tick = setInterval(function () {
          bubble.textContent = L.text.slice(0, ++i);
          if (i >= L.text.length) { clearInterval(tick); setTimeout(function () { li++; typeLine(); }, 3600); }
        }, 34);
      };
      typeLine();
    }
  }
  $$('[data-mascot="progress"]').forEach(function (m) { setMood(m, readiness().pct); });

  // continue button and progress text
  $$('[data-continue]').forEach(function (a) {
    var nl = nextLunch();
    if (doneCount() === 0) return;
    if (nl) { a.href = lunchUrl(nl); a.innerHTML = '▶ Continue: Episode ' + nl.n; }
    else { a.href = ROOT + 'labs/32-advanced-capstone-challenge.html'; a.innerHTML = '🌟 Take the season finale'; }
  });

  // 60-minute clock
  var clock = $('.lunch-clock');
  if (clock) {
    var segs = $$('.lunch-clock .seg'), items = $$('.seg-item'), center = $('[data-clock-label]'), centerSub = $('[data-clock-sub]');
    var pick = function (i) {
      segs.forEach(function (s, k) { s.classList.toggle('active', k === i); });
      items.forEach(function (s, k) { s.classList.toggle('active', k === i); });
      if (center && items[i]) { center.textContent = items[i].getAttribute('data-min') + ' min'; centerSub.textContent = items[i].getAttribute('data-name'); }
    };
    segs.forEach(function (s, i) { s.addEventListener('mouseenter', function () { pick(i); }); s.addEventListener('click', function () { pick(i); }); });
    items.forEach(function (s, i) { s.addEventListener('mouseenter', function () { pick(i); }); s.addEventListener('focus', function () { pick(i); }); });
    clock.addEventListener('mouseleave', function () { segs.forEach(function (s) { s.classList.remove('active'); }); items.forEach(function (s) { s.classList.remove('active'); }); if (center) { center.textContent = '60 min'; centerSub.textContent = 'one lunch'; } });
  }

  // director gauge (landing + lunchbox)
  $$('[data-gauge]').forEach(function (g) {
    var r = readiness(), fill = $('.fill', g), needle = $('.needle', g), pct = $('.pct', g);
    var len = fill.getTotalLength ? fill.getTotalLength() : 377;
    fill.style.strokeDasharray = len; fill.style.strokeDashoffset = len;
    var apply = function () {
      fill.style.strokeDashoffset = len * (1 - r.pct / 100);
      needle.style.transform = 'rotate(' + (-90 + 180 * r.pct / 100) + 'deg)';
      var t0 = performance.now();
      (function step(t) { var k = Math.min(1, (t - t0) / 1400); pct.textContent = Math.round(r.pct * k) + '%'; if (k < 1) requestAnimationFrame(step); })(t0);
    };
    if ('IntersectionObserver' in window) { var o = new IntersectionObserver(function (es) { if (es[0].isIntersecting) { apply(); o.disconnect(); } }); o.observe(g); } else apply();
  });
  $$('[data-director-answer]').forEach(function (el) { el.textContent = '“' + readiness().answer + '”'; });
  $$('[data-director-when]').forEach(function (el) { var r = readiness(); el.textContent = r.lunch ? 'Your answer after Episode ' + r.lunch.n + ' · ' + r.lunch.ep : 'Your answer today, before Episode 01'; });
  $$('[data-answer-log]').forEach(function (el) {
    el.innerHTML = C.lunches.map(function (l) { var p = partOf[l.part] || {}; return '<span class="' + (S.done[l.n] ? 'on' : '') + '" style="--c:' + p.color + '" title="Episode ' + l.n + '"></span>'; }).join('');
  });

  // metro map
  var metroHost = $('[data-metro]');
  var tip;
  function showTip(l, el) {
    if (!tip) { tip = doc.createElement('div'); tip.className = 'metro-tip'; body.appendChild(tip); }
    var st = S.done[l.n] ? '✓ Finished' : (nextLunch() === l ? '● Up next' : '○ Not started');
    tip.innerHTML = '<span class="t-meta">Episode ' + l.n + ' · ' + esc((partOf[l.part] || {}).name || '') + ' · ' + st + '</span><b>' + esc(l.ep) + '</b>' + esc(l.title) + '<br><span style="opacity:.8">' + esc(l.hook) + '</span>';
    var r = el.getBoundingClientRect(); tip.classList.add('show');
    var x = Math.min(innerWidth - 316, Math.max(8, r.left + r.width / 2 - 150)), y = r.top - tip.offsetHeight - 14;
    if (y < 70) y = r.bottom + 14;
    tip.style.left = x + 'px'; tip.style.top = y + 'px';
  }
  function hideTip() { if (tip) tip.classList.remove('show'); }
  function drawMetro() {
    if (!metroHost) return;
    var w = metroHost.clientWidth, vertical = w < 700, NS = 'http://www.w3.org/2000/svg';
    var cur = nextLunch(), stops = C.lunches.slice();
    if (C.finale) stops.push({ n: '32', slug: C.finale.slug, ep: C.finale.ep, title: 'Advanced capstone challenge', hook: C.finale.hook, station: C.finale.station, part: 5, finale: true });
    var pos = [], W, H;
    if (!vertical) {
      W = 1160; H = 640;
      var rows = [[0, 7], [7, 14], [14, 21], [21, stops.length]], ys = [90, 245, 400, 555];
      rows.forEach(function (rw, ri) {
        var cnt = rw[1] - rw[0], x0 = 90, x1 = W - 90, step = (x1 - x0) / Math.max(1, cnt - 1);
        for (var i = 0; i < cnt; i++) { var x = ri % 2 === 0 ? x0 + i * step : x1 - i * step; pos.push({ x: x, y: ys[ri], row: ri, i: i }); }
      });
    } else {
      W = 360; H = stops.length * 62 + 40;
      stops.forEach(function (s, i) { pos.push({ x: 40, y: 40 + i * 62, row: i, i: 0 }); });
    }
    var svg = doc.createElementNS(NS, 'svg'); svg.setAttribute('viewBox', '0 0 ' + W + ' ' + H); svg.setAttribute('class', 'metro'); svg.setAttribute('role', 'img');
    svg.setAttribute('aria-label', 'Journey map: ' + doneCount() + ' of ' + C.lunches.length + ' lunches finished');
    var html = '';
    function seg(a, b) {
      if (a.y === b.y || vertical) return 'M' + a.x + ',' + a.y + ' L' + b.x + ',' + b.y;
      var dir = a.x > W / 2 ? 1 : -1, bx = a.x + dir * 70;
      return 'M' + a.x + ',' + a.y + ' C' + bx + ',' + a.y + ' ' + bx + ',' + b.y + ' ' + b.x + ',' + b.y;
    }
    for (var i = 1; i < pos.length; i++) {
      var p = partOf[stops[i].part] || {}; var d = seg(pos[i - 1], pos[i]);
      html += '<path class="line-shadow" d="' + d + '"/><path class="line" d="' + d + '" stroke="' + p.color + '"' + (S.done[stops[i - 1].n] && (S.done[stops[i].n] || stops[i] === cur) ? '' : ' stroke-opacity="0.55"') + '/>';
    }
    var lastPart = 0;
    stops.forEach(function (s, i) {
      var p = partOf[s.part] || {}, q = pos[i];
      if (s.part !== lastPart && !vertical) {
        lastPart = s.part;
        var lx = q.row % 2 === 0 ? q.x - 40 : q.x + 40, anchor = q.row % 2 === 0 ? 'start' : 'end';
        html += '<text class="district" x="' + lx + '" y="' + (q.y - 52) + '" fill="' + p.color + '" text-anchor="' + anchor + '">' + p.icon + ' ' + esc(p.name) + '</text>';
      }
      var done = s.finale ? !!(S.labs['32'] || {}).done : !!S.done[s.n], isCur = !done && (s === cur || (!cur && s.finale));
      var url = s.finale ? labUrl(s.slug) : lunchUrl(s);
      var above = vertical ? false : (i % 2 === 0);
      var ly = vertical ? q.y + 5 : (above ? q.y - 26 : q.y + 38), lx2 = vertical ? q.x + 30 : q.x, la = vertical ? 'start' : 'middle';
      var label = vertical ? (s.n + ' · ' + s.ep) : s.station;
      html += '<g class="station' + (done ? ' done' : '') + (isCur ? ' current' : '') + '" style="--c:' + p.color + '" data-i="' + i + '">' +
        '<a href="' + url + '" aria-label="Episode ' + s.n + ': ' + esc(s.ep) + (done ? ' (finished)' : '') + '">' +
        '<circle class="halo" cx="' + q.x + '" cy="' + q.y + '" r="16"/>' +
        '<circle class="dot" cx="' + q.x + '" cy="' + q.y + '" r="' + (s.finale ? 17 : 14) + '" stroke="' + p.color + '"/>' +
        '<text class="num" x="' + q.x + '" y="' + (q.y + 4) + '" text-anchor="middle">' + (s.finale ? '★' : (done ? '✓' : +s.n)) + '</text>' +
        '<text class="lbl" x="' + lx2 + '" y="' + ly + '" text-anchor="' + la + '">' + esc(label) + '</text></a></g>';
      if (isCur) {
        var fy = vertical ? q.y - 8 : q.y - 64, fx = vertical ? W - 116 : q.x - 52;
        if (!vertical) html += '<g class="flag"><rect class="here-bg" x="' + fx + '" y="' + fy + '" rx="10" width="104" height="22"/><text class="here" x="' + (fx + 52) + '" y="' + (fy + 15) + '" text-anchor="middle">YOU ARE HERE</text></g>';
      }
    });
    svg.innerHTML = '<defs></defs>' + html;
    metroHost.innerHTML = ''; metroHost.appendChild(svg);
    $$('.station', svg).forEach(function (g) {
      var s = stops[+g.getAttribute('data-i')], a = $('a', g);
      var showIt = function () { showTip(s, $('circle.dot', g)); };
      a.addEventListener('mouseenter', showIt); a.addEventListener('focus', showIt);
      a.addEventListener('mouseleave', hideTip); a.addEventListener('blur', hideTip);
    });
    var pb = $('[data-metro-bar]'); if (pb) pb.style.inlineSize = (doneCount() / C.lunches.length * 100) + '%';
    var pt = $('[data-metro-text]'); if (pt) pt.textContent = doneCount() + ' / ' + C.lunches.length + ' lunches';
  }
  if (metroHost) { drawMetro(); var rz; addEventListener('resize', function () { clearTimeout(rz); rz = setTimeout(drawMetro, 150); }); addEventListener('scroll', hideTip, { passive: true }); }

  // episode grid
  var grid = $('[data-ep-grid]');
  if (grid) {
    var cards = $$('.ep-card', grid);
    cards.forEach(function (c) { if (S.done[c.getAttribute('data-n')]) c.classList.add('done'); });
    var filter = 'all', q = '';
    var apply2 = function () {
      cards.forEach(function (c) {
        var n = +c.getAttribute('data-n'), d = !!S.done[c.getAttribute('data-n')];
        var ok = filter === 'all' || (filter === 's1' && n <= 21) || (filter === 's2' && n >= 22) || (filter === 'todo' && !d) || (filter === 'done' && d);
        if (ok && q) ok = c.textContent.toLowerCase().indexOf(q) >= 0;
        c.style.display = ok ? '' : 'none';
      });
    };
    $$('[data-filter]').forEach(function (b) {
      b.addEventListener('click', function () { filter = b.getAttribute('data-filter'); $$('[data-filter]').forEach(function (x) { x.setAttribute('aria-pressed', x === b ? 'true' : 'false'); }); apply2(); });
    });
    var sb = $('[data-ep-search]'); if (sb) sb.addEventListener('input', function () { q = sb.value.trim().toLowerCase(); apply2(); });
  }

  // badges (landing preview + lunchbox)
  $$('[data-badges]').forEach(function (host) {
    var lim = +host.getAttribute('data-badges') || 999, list = badgeList();
    host.innerHTML = list.slice(0, lim).map(function (b) {
      return '<div class="badge-tile' + (b.got ? '' : ' locked') + '" title="' + esc(b.desc) + '"><span class="medal" aria-hidden="true">' + b.icon + '</span>' + esc(b.name) +
        '<span class="when">' + (b.got ? (b.got > 1 ? 'Earned ' + new Date(b.got).toLocaleDateString() : 'Earned') : (b.n ? 'Episode ' + b.n : 'Locked')) + '</span></div>';
    }).join('');
  });
  $$('[data-badge-count]').forEach(function (el) { var l = badgeList(); el.textContent = l.filter(function (b) { return b.got; }).length + ' of ' + l.length; });

  /* ======================================================= EPISODE PAGE */
  var N = body.getAttribute('data-lunch');
  var L = N ? byN[N] : null;
  if (L) {
    // scrollspy for the lunch clock rail + mobile pills
    var targets = $$('[data-spy]');
    var links = $$('.rail a[href^="#"], .mobile-seg a[href^="#"]');
    if ('IntersectionObserver' in window && targets.length) {
      var spy = new IntersectionObserver(function (es) {
        es.forEach(function (e) {
          if (!e.isIntersecting) return;
          var id = e.target.id, idx = targets.indexOf(e.target);
          links.forEach(function (a) { var on = a.getAttribute('href') === '#' + id; a.classList.toggle('active', on); var li = a.parentElement; if (li && li.tagName === 'LI') li.classList.toggle('active', on); });
          targets.forEach(function (t, k) { $$('.rail a[href="#' + t.id + '"]').forEach(function (a) { var li = a.parentElement; if (li) li.classList.toggle('seen', k <= idx); }); });
          var m = $('.mobile-seg a.active'); if (m && m.scrollIntoView && !reduceMotion) m.scrollIntoView({ block: 'nearest', inline: 'center' });
        });
      }, { rootMargin: '-40% 0px -55% 0px' });
      targets.forEach(function (t) { spy.observe(t); });
    }
    // objectives
    $$('[data-obj]').forEach(function (b) {
      var i = b.getAttribute('data-obj'); S.obj[N] = S.obj[N] || {};
      b.setAttribute('aria-pressed', S.obj[N][i] ? 'true' : 'false'); b.textContent = '✓';
      b.addEventListener('click', function () {
        var on = !S.obj[N][i]; S.obj[N][i] = on ? 1 : 0; b.setAttribute('aria-pressed', on ? 'true' : 'false'); save();
        if (on) xpToast(5, 'You can do this now');
      });
    });
    // pause-and-think
    $$('.callout.think').forEach(function (c, i) {
      var key = N + '-' + i, btn = doc.createElement('button');
      btn.className = 'btn btn-sm think-btn'; c.appendChild(btn);
      var paint = function () { var on = !!S.think[key]; c.classList.toggle('thought', on); btn.textContent = on ? '✓ Thought about it' : '💭 I have thought about it'; };
      btn.addEventListener('click', function () { var on = !S.think[key]; S.think[key] = on ? 1 : 0; save(); paint(); if (on) xpToast(5, 'Good thinking'); });
      paint();
    });
    // quiz
    var qcards = $$('.qcard'); S.quiz[N] = S.quiz[N] || {};
    var ring = $('[data-score-ring]'), scoreText = $('[data-score-text]'), scoreNote = $('[data-score-note]');
    var paintScore = function () {
      var g = S.quiz[N], graded = Object.keys(g).length, right = Object.keys(g).filter(function (k) { return g[k] === 1; }).length;
      if (ring) { ring.style.setProperty('--p', Math.round(right / Math.max(1, qcards.length) * 100)); }
      if (scoreText) scoreText.textContent = right + '/' + qcards.length;
      if (scoreNote) scoreNote.textContent = graded < qcards.length ? 'Answer in your head, reveal, then be honest with yourself.' :
        (right === qcards.length ? 'Perfect score! 🎯 You are ready for the lab.' : right >= 3 ? 'Solid. Re-read the scenes behind the ones you missed.' : 'Worth a second look — the takeaways below will help.');
    };
    qcards.forEach(function (card) {
      var k = card.getAttribute('data-q'), rb = $('.reveal-btn', card);
      var paint = function () {
        var v = S.quiz[N][k]; card.classList.toggle('right', v === 1); card.classList.toggle('wrong', v === 0);
        $$('.grade button', card).forEach(function (b) { b.setAttribute('aria-pressed', String(+b.getAttribute('data-grade') === v)); });
      };
      if (S.quiz[N][k] !== undefined) { card.classList.add('open'); rb.textContent = 'Hide answer'; }
      rb.addEventListener('click', function () { var o = card.classList.toggle('open'); rb.textContent = o ? 'Hide answer' : 'Reveal answer'; rb.setAttribute('aria-expanded', o ? 'true' : 'false'); });
      $$('.grade button', card).forEach(function (b) {
        b.addEventListener('click', function () {
          var v = +b.getAttribute('data-grade'), was = S.quiz[N][k]; S.quiz[N][k] = v; save(); paint(); paintScore();
          if (v === 1 && was !== 1) xpToast(20, 'Correct answer');
          if (v === 0) { card.classList.remove('wiggle'); void card.offsetWidth; card.classList.add('wiggle'); }
          var g = S.quiz[N]; if (Object.keys(g).length === qcards.length && Object.keys(g).every(function (x) { return g[x] === 1; }) && was !== 1) { confetti(90); toast('🎯 Perfect score!'); }
        });
      });
      paint();
    });
    paintScore();
    // takeaways → notebook
    $$('[data-pin]').forEach(function (b) {
      var i = b.getAttribute('data-pin'), text = $('p', b.closest('.tk')).textContent;
      var has = function () { return S.notes.some(function (x) { return x.n === N && String(x.i) === i; }); };
      var paint = function () { var on = has(); b.setAttribute('aria-pressed', on ? 'true' : 'false'); b.textContent = on ? '📌 Pinned' : '📌 Pin to notebook'; };
      b.addEventListener('click', function () {
        if (has()) S.notes = S.notes.filter(function (x) { return !(x.n === N && String(x.i) === i); });
        else { S.notes.push({ n: N, i: i, text: text, t: Date.now() }); xpToast(5, 'Saved to your notebook'); }
        save(); paint();
      });
      paint();
    });
    // demo theatre
    var th = $('.theatre');
    if (th) {
      var fsBtn = $('[data-fullscreen]', th), frame = $('iframe', th);
      if (fsBtn) fsBtn.addEventListener('click', function () {
        var on = th.classList.toggle('fullscreen'); fsBtn.textContent = on ? '✕ Exit theatre' : '⤢ Theatre mode'; body.style.overflow = on ? 'hidden' : '';
      });
      doc.addEventListener('keydown', function (e) { if (e.key === 'Escape' && th.classList.contains('fullscreen')) fsBtn.click(); });
      var watch = setInterval(function () {
        try {
          var d = frame.contentWindow && frame.contentWindow.__lunchDemo;
          if (d && d.steps && d.current() === d.steps.length - 1 && !S.demo[N]) {
            S.demo[N] = Date.now(); save(); xpToast(30, 'Demo watched to the end 🎬'); clearInterval(watch);
            $$('.rail a[href="#demo"]').forEach(function (a) { a.parentElement.classList.add('seen'); });
          }
        } catch (e) { clearInterval(watch); }
      }, 1500);
    }
    // finish & celebrate
    var finishBox = $('.finish');
    var paintFinish = function () {
      var d = !!S.done[N];
      if (finishBox) finishBox.classList.toggle('done', d);
      $$('[data-finish]').forEach(function (b) { b.innerHTML = d ? '✓ Lunch finished' : b.getAttribute('data-label'); });
      $$('[data-undo]').forEach(function (u) { u.hidden = !d; });
    };
    $$('[data-finish]').forEach(function (b) {
      b.setAttribute('data-label', b.innerHTML);
      b.addEventListener('click', function () {
        var before = badgeList().filter(function (x) { return x.got; }).map(function (x) { return x.id; });
        var first = !S.done[N];
        if (first) S.done[N] = Date.now();
        save(); paintFinish();
        var after = badgeList().filter(function (x) { return x.got && before.indexOf(x.id) < 0; });
        var nl = C.lunches[C.lunches.indexOf(L) + 1];
        var teaser = nl ? '<div class="teaser"><b>Next episode · ' + nl.n + '</b><h4>' + esc(nl.ep) + '</h4><p>' + esc(nl.hook) + '</p><p style="margin-top:10px"><a class="btn btn-warm btn-sm" href="' + lunchUrl(nl) + '">Watch Episode ' + nl.n + ' →</a></p></div>'
          : '<div class="teaser"><b>Season finale</b><h4>' + esc(C.finale.ep) + '</h4><p>' + esc(C.finale.hook) + '</p><p style="margin-top:10px"><a class="btn btn-warm btn-sm" href="' + labUrl(C.finale.slug) + '">Take the challenge →</a></p></div>';
        var extra = after.filter(function (x) { return x.special; }).map(function (x) { return '<span class="chip ok">' + x.icon + ' ' + esc(x.name) + '</span>'; }).join(' ');
        openModal('<div class="medal-xl" aria-hidden="true">' + L.badge.icon + '</div><p class="kicker" style="justify-content:center;margin-top:14px">Badge unlocked</p>' +
          '<h2 style="margin:.1em 0">' + esc(L.badge.name) + '</h2><p class="muted">' + esc(L.badge.desc) + '</p>' +
          (first ? '<div class="xp">+100 XP</div>' : '') + (extra ? '<div class="chips" style="justify-content:center">' + extra + '</div>' : '') +
          '<p style="margin:14px 0 0;font-weight:700">' + esc('Now you could tell Ibu Sari: “' + L.answer + '”') + '</p>' + teaser);
        if (first) confetti(200);
      });
    });
    $$('[data-undo]').forEach(function (u) { u.addEventListener('click', function (e) { e.preventDefault(); delete S.done[N]; save(); paintFinish(); toast('Marked as not finished'); }); });
    paintFinish();
    // lunch timer
    var SEGS = [[5, 'Scenario', '#menu'], [30, 'Reading', '#reading'], [45, 'Demo', '#demo'], [50, 'Knowledge check', '#quiz'], [55, 'Takeaways & lab', '#takeaways'], [60, 'Buffer — finish your lunch', '#finish']];
    var timerEl = $('.timer'), tTime = timerEl && $('.t-time', timerEl), tSeg = timerEl && $('.t-seg', timerEl), tRing = timerEl && $('.t-ring', timerEl), tick = null, lastSeg = -1;
    var startTimer = function (from) {
      S.timer[N] = from; save(); timerEl.classList.add('on'); clearInterval(tick); lastSeg = -1;
      var upd = function () {
        var el = (Date.now() - S.timer[N]) / 1000, left = Math.max(0, 3600 - el), mm = Math.floor(left / 60), ss = Math.floor(left % 60);
        tTime.textContent = (mm < 10 ? '0' : '') + mm + ':' + (ss < 10 ? '0' : '') + ss;
        tRing.style.setProperty('--p', Math.min(100, el / 36));
        var minute = el / 60, si = 0; while (si < SEGS.length - 1 && minute >= SEGS[si][0]) si++;
        tSeg.textContent = left <= 0 ? 'Lunch is over 🍵' : 'Now: ' + SEGS[si][1];
        if (si !== lastSeg) { if (lastSeg !== -1) toast('⏱ Time for ' + SEGS[si][1].toLowerCase() + ' — <a style="color:var(--mango)" href="' + SEGS[si][2] + '">jump there</a>', 5000); lastSeg = si; }
        if (left <= 0) clearInterval(tick);
      };
      upd(); tick = setInterval(upd, 1000);
    };
    $$('[data-timer-start]').forEach(function (b) { b.addEventListener('click', function () { startTimer(Date.now()); toast('🍱 Lunch started. Enjoy — 60 minutes on the clock.'); }); });
    var stopBtn = timerEl && $('[data-timer-stop]', timerEl);
    if (stopBtn) stopBtn.addEventListener('click', function () { clearInterval(tick); delete S.timer[N]; save(); timerEl.classList.remove('on'); });
    if (timerEl && S.timer[N] && Date.now() - S.timer[N] < 3600 * 1000 * 1.5) startTimer(S.timer[N]);
  }

  /* ======================================================= LABS HUB */
  var tgrid = $('[data-ticket-grid]');
  if (tgrid) {
    var tcards = $$('.tcard', tgrid), costF = 'all', partF = 'all', q2 = '';
    tcards.forEach(function (c) {
      var n = c.getAttribute('data-n'), st = S.labs[n] || {}, el = $('.status', c), tasks = Object.keys(st.tasks || {}).length;
      if (st.done) { el.textContent = st.cleaned ? '✓ Done · cleaned up' : '✓ Done'; el.className = 'status st-done'; }
      else if (tasks) { el.textContent = '◐ In progress · ' + tasks + ' task' + (tasks > 1 ? 's' : '') + ' done'; el.className = 'status st-progress'; }
    });
    var applyT = function () {
      tcards.forEach(function (c) {
        var ok = (costF === 'all' || c.getAttribute('data-cost') === costF) && (partF === 'all' || c.getAttribute('data-part') === partF);
        if (ok && q2) ok = c.textContent.toLowerCase().indexOf(q2) >= 0;
        c.style.display = ok ? '' : 'none';
      });
    };
    $$('[data-cost-filter]').forEach(function (b) { b.addEventListener('click', function () { costF = b.getAttribute('data-cost-filter'); $$('[data-cost-filter]').forEach(function (x) { x.setAttribute('aria-pressed', String(x === b)); }); applyT(); }); });
    $$('[data-part-filter]').forEach(function (b) { b.addEventListener('click', function () { partF = b.getAttribute('data-part-filter'); $$('[data-part-filter]').forEach(function (x) { x.setAttribute('aria-pressed', String(x === b)); }); applyT(); }); });
    var ls = $('[data-lab-search]'); if (ls) ls.addEventListener('input', function () { q2 = ls.value.trim().toLowerCase(); applyT(); });
  }

  /* ======================================================= LAB PAGE */
  var LN = body.getAttribute('data-lab');
  if (LN) {
    var st = lab(LN);
    var setMode = function (m) {
      body.classList.toggle('mode-challenge', m === 'challenge'); body.classList.toggle('mode-guided', m !== 'challenge');
      $$('[data-mode]').forEach(function (b) { b.setAttribute('aria-pressed', String(b.getAttribute('data-mode') === m)); });
      st.mode = m; save();
    };
    $$('[data-mode]').forEach(function (b) { b.addEventListener('click', function () { setMode(b.getAttribute('data-mode')); if (b.getAttribute('data-mode') === 'challenge') { var cb = $('.lab-section[data-kind="challenge"]'); if (cb) cb.scrollIntoView({ behavior: reduceMotion ? 'auto' : 'smooth' }); } }); });
    setMode(st.mode || 'guided');
    var taskBtns = $$('[data-task]');
    var paintTasks = function () {
      var done = 0;
      taskBtns.forEach(function (b) {
        var id = b.getAttribute('data-task'), on = !!st.tasks[id]; if (on) done++;
        b.setAttribute('aria-pressed', String(on)); b.textContent = on ? '✓ Done' : 'Mark done';
        var sec = b.closest('.lab-section'); if (!sec) return;
        sec.classList.toggle('is-done', on);
        $$('.rail a[href="#' + sec.id + '"]').forEach(function (a) { a.parentElement.classList.toggle('seen', on); });
      });
      var pb2 = $('[data-task-bar]'); if (pb2) pb2.style.inlineSize = (taskBtns.length ? done / taskBtns.length * 100 : 0) + '%';
      var pt2 = $('[data-task-text]'); if (pt2) pt2.textContent = done + ' of ' + taskBtns.length + ' tasks';
      var ban = $('.cleanup-banner'); if (ban) ban.classList.toggle('show', done > 0 && !st.cleaned && !!$('[data-cleanup]'));
    };
    taskBtns.forEach(function (b) {
      b.addEventListener('click', function () {
        var id = b.getAttribute('data-task'); if (st.tasks[id]) delete st.tasks[id]; else { st.tasks[id] = Date.now(); xpToast(15, 'Task complete'); }
        save(); paintTasks();
      });
    });
    $$('[data-cleanup]').forEach(function (b) {
      var paint = function () { b.setAttribute('aria-pressed', String(!!st.cleaned)); b.textContent = st.cleaned ? '✓ Cleaned up — nothing left running' : '🧹 I ran cleanup.sh'; };
      b.addEventListener('click', function () { if (st.cleaned) delete st.cleaned; else { st.cleaned = Date.now(); xpToast(25, 'Clean plate'); } save(); paint(); paintTasks(); });
      paint();
    });
    $$('[data-lab-complete]').forEach(function (b) {
      var paint = function () { b.textContent = st.done ? '✓ Lab complete' : b.getAttribute('data-label'); };
      b.setAttribute('data-label', b.textContent);
      b.addEventListener('click', function () {
        var first = !st.done; if (first) st.done = Date.now(); save(); paint();
        if (first) { confetti(180); var fin = LN === '32';
          openModal('<div class="medal-xl" aria-hidden="true">' + (fin ? C.finale.badge.icon : '🧪') + '</div><p class="kicker" style="justify-content:center;margin-top:14px">Lab complete</p><h2>' + (fin ? esc(C.finale.badge.name) : 'Hands-on win') + '</h2><div class="xp">+150 XP</div>' +
            (st.cleaned ? '<p>And you cleaned up. Ibu Sari approves. 🧹</p>' : '<p><b>One last thing:</b> run <code>bash cleanup.sh</code> so nothing keeps costing money.</p>')); }
      });
      paint();
    });
    paintTasks();
    // rail spy on lab sections
    var secs = $$('.lab-section[id]'), rl = $$('.rail a[href^="#"]');
    if ('IntersectionObserver' in window && secs.length) {
      var spy2 = new IntersectionObserver(function (es) { es.forEach(function (e) { if (e.isIntersecting) rl.forEach(function (a) { a.parentElement.classList.toggle('active', a.getAttribute('href') === '#' + e.target.id); }); }); }, { rootMargin: '-40% 0px -55% 0px' });
      secs.forEach(function (s) { spy2.observe(s); });
    }
  }

  /* ======================================================= DEMOS HUB */
  var dgrid = $('[data-demo-grid]');
  if (dgrid) {
    var scaleThumbs = function () { $$('.dthumb', dgrid).forEach(function (t) { t.style.setProperty('--s', t.clientWidth / 1200); }); };
    scaleThumbs(); addEventListener('resize', scaleThumbs);
    var lazy = function (f) { if (!f.src) f.src = f.getAttribute('data-src'); };
    if ('IntersectionObserver' in window) {
      var io2 = new IntersectionObserver(function (es) { es.forEach(function (e) { if (e.isIntersecting) { lazy(e.target); io2.unobserve(e.target); } }); }, { rootMargin: '200px' });
      $$('iframe[data-src]', dgrid).forEach(function (f) { io2.observe(f); });
    } else $$('iframe[data-src]', dgrid).forEach(lazy);
    $$('[data-demo-filter]').forEach(function (b) {
      b.addEventListener('click', function () {
        var f = b.getAttribute('data-demo-filter');
        $$('[data-demo-filter]').forEach(function (x) { x.setAttribute('aria-pressed', String(x === b)); });
        $$('.dcard', dgrid).forEach(function (c) { c.style.display = (f === 'all' || c.getAttribute('data-part') === f) ? '' : 'none'; });
        scaleThumbs();
      });
    });
    $$('.dcard', dgrid).forEach(function (c) { if (S.demo[c.getAttribute('data-n')]) $('.play', c).textContent = '✓'; });
  }

  /* ======================================================= LUNCHBOX */
  if (body.getAttribute('data-page') === 'lunchbox') {
    var x = xp(), lv = level(x);
    var setText = function (sel, v) { $$(sel).forEach(function (el) { el.textContent = v; }); };
    setText('[data-level-name]', lv.name); setText('[data-xp]', x + ' XP');
    setText('[data-xp-next]', lv.next ? (lv.next.xp - x) + ' XP to “' + lv.next.name + '”' : 'Top level reached. Legendary.');
    var xb = $('[data-xp-bar]'); if (xb) setTimeout(function () { xb.style.inlineSize = (lv.next ? (x - lv.at) / (lv.next.xp - lv.at) * 100 : 100) + '%'; }, 200);
    var icons = ['🌱', '🧑‍💻', '🛠️', '☁️', '🚀', '🏗️', '👑']; setText('[data-level-icon]', icons[Math.min(icons.length - 1, lv.idx)]);
    setText('[data-k-lunches]', doneCount() + '/' + C.lunches.length); setText('[data-k-labs]', labsDone() + '/32');
    var gq = quizGraded(); setText('[data-k-quiz]', gq ? Math.round(quizCorrect() / gq * 100) + '%' : '—'); setText('[data-k-streak]', streak() + ' 🔥');
    $$('[data-season-bar]').forEach(function (b) { var r = b.getAttribute('data-season-bar').split('-').map(Number); var tot = r[1] - r[0] + 1; setTimeout(function () { b.style.inlineSize = (doneCount(r) / tot * 100) + '%'; }, 200); });
    $$('[data-season-text]').forEach(function (b) { var r = b.getAttribute('data-season-text').split('-').map(Number); b.textContent = doneCount(r) + ' / ' + (r[1] - r[0] + 1); });
    // notebook
    var nb = $('[data-notebook]');
    var paintNotes = function () {
      if (!nb) return;
      if (!S.notes.length) { nb.innerHTML = '<div class="empty">Your notebook is empty. Pin key takeaways at the end of any lunch and they will appear here.</div>'; return; }
      var sorted = S.notes.slice().sort(function (a, b) { return a.n === b.n ? a.i - b.i : a.n < b.n ? -1 : 1; });
      nb.innerHTML = sorted.map(function (x, k) {
        var l = byN[x.n] || {}; var p = partOf[l.part] || {};
        return '<div class="note-item" style="--c:' + p.color + '"><span class="n">EP ' + esc(x.n) + '</span><div>' + esc(x.text) + '<br><a class="muted" style="font-size:.8rem" href="' + (l.slug ? lunchUrl(l) : '#') + '">' + esc(l.ep || '') + '</a></div><button class="btn btn-sm" data-unpin="' + k + '" aria-label="Remove note">✕</button></div>';
      }).join('');
      $$('[data-unpin]', nb).forEach(function (b) { b.addEventListener('click', function () { var it = sorted[+b.getAttribute('data-unpin')]; S.notes = S.notes.filter(function (y) { return y !== it; }); save(); paintNotes(); }); });
    };
    paintNotes();
    var asMd = function () {
      return '# My Azure lunch notebook\n\n' + S.notes.slice().sort(function (a, b) { return a.n < b.n ? -1 : a.n > b.n ? 1 : a.i - b.i; }).map(function (x) { var l = byN[x.n] || {}; return '- **Episode ' + x.n + ' · ' + (l.ep || '') + ':** ' + x.text; }).join('\n') + '\n';
    };
    var cpy = $('[data-notes-copy]'); if (cpy) cpy.addEventListener('click', function () { (navigator.clipboard ? navigator.clipboard.writeText(asMd()) : Promise.reject()).then(function () { toast('Copied as Markdown ✓'); }, function () { fallbackCopy(asMd()); toast('Copied ✓'); }); });
    var dl = function (name, text, type) { var a = doc.createElement('a'); a.href = URL.createObjectURL(new Blob([text], { type: type })); a.download = name; body.appendChild(a); a.click(); setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 500); };
    var dln = $('[data-notes-download]'); if (dln) dln.addEventListener('click', function () { dl('azure-lunch-notebook.md', asMd(), 'text/markdown'); });
    // certificate
    var nameIn = $('[data-cert-name]'), cert = $('.cert');
    var paintCert = function () {
      if (!cert) return;
      var nm = (S.name || '').trim() || 'Your name here', all = doneCount() === C.lunches.length;
      setText('[data-c-name]', nm);
      setText('[data-c-title]', all ? 'Certificate of Completion' : 'Certificate of Progress');
      setText('[data-c-body]', all ? 'has completed all ' + C.lunches.length + ' lunches of Azure Fundamentals: One Lunch at a Time — from the pantry server to governance at scale.'
        : 'has completed ' + doneCount() + ' of ' + C.lunches.length + ' lunches of Azure Fundamentals: One Lunch at a Time, and earned ' + x + ' XP as a ' + lv.name.toLowerCase() + '.');
      setText('[data-c-date]', new Date().toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' }));
      setText('[data-c-medals]', badgeList().filter(function (b) { return b.got; }).map(function (b) { return b.icon; }).slice(0, 14).join(' ') || '🍱');
    };
    if (nameIn) { nameIn.value = S.name || ''; nameIn.addEventListener('input', function () { S.name = nameIn.value.slice(0, 60); save(); paintCert(); }); }
    paintCert();
    var pr = $('[data-cert-print]'); if (pr) pr.addEventListener('click', function () { window.print(); });
    // data tools
    var ex = $('[data-export]'); if (ex) ex.addEventListener('click', function () { dl('azure-lunch-progress.json', JSON.stringify(S, null, 2), 'application/json'); });
    var im = $('[data-import]'); if (im) im.addEventListener('change', function () {
      var f = im.files && im.files[0]; if (!f) return; var rdr = new FileReader();
      rdr.onload = function () { try { var d = JSON.parse(rdr.result); if (!d || typeof d !== 'object' || !d.done) throw new Error('bad'); var b2 = blank(); for (var k2 in b2) { if (!(k2 in d)) d[k2] = b2[k2]; } S = d; save(); location.reload(); } catch (e) { toast('That file does not look like a progress export.'); } };
      rdr.readAsText(f);
    });
    var rs = $('[data-reset]'); if (rs) rs.addEventListener('click', function () { if (confirm('Reset all progress, badges and notes in this browser?')) { S = blank(); save(); location.reload(); } });
  }

  updateHud();
})();

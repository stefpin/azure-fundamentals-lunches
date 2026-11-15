/* =============================================================================
   Lunch Tutor — the AI tutor panel (pilot) on lunch and lab pages.
   Hand-written, plain ES2017, no build step. Settings and all interface text come from
   assets/tutor-config.js (window.TUTOR_CFG), which tools/build_site.py generates from
   tools/site/site-config.json ("tutor") and tools/site/strings.py (TUTOR).

   Activation: site config tutor.enabled is true, or the page was opened with ?tutor=preview
   (remembered for this browser tab in sessionStorage 'azlunch.tutor'), or that flag is set.
   ?tutor=off forgets the flag. Without activation this file does nothing else: no network
   calls and no sign-in library. The sign-in library (MSAL Browser) is loaded only when the
   panel is opened for the first time.
   ============================================================================= */
(function () {
  'use strict';

  var doc = document, body = doc.body, html = doc.documentElement;
  var CFG = window.TUTOR_CFG;
  if (!body || !CFG || typeof CFG !== 'object') return;
  var PAGE = body.getAttribute('data-page');
  if (PAGE !== 'lunch' && PAGE !== 'lab') return;

  /* ------------------------------------------------------------ activation */
  var FLAG = 'azlunch.tutor';
  var mode = '';
  try { mode = new URLSearchParams(location.search).get('tutor') || ''; } catch (e) { /* very old browser */ }
  var flagged = false;
  try {
    if (mode === 'off') sessionStorage.removeItem(FLAG);
    else if (mode === 'preview') sessionStorage.setItem(FLAG, 'preview');
    flagged = sessionStorage.getItem(FLAG) === 'preview';
  } catch (e) { /* storage blocked: ?tutor=preview still works on this page */ }
  if (!(CFG.enabled === true || mode === 'preview' || flagged)) return;

  var LUNCH = body.getAttribute(PAGE === 'lab' ? 'data-lab' : 'data-lunch') || '';
  if (!/^\d{2}$/.test(LUNCH)) return;

  /* -------------------------------------------------------------- settings */
  var LANG = /^id/i.test(html.getAttribute('lang') || '') ? 'id' : 'en';
  var UI = (CFG.ui && (CFG.ui[LANG] || CFG.ui.en)) || {};
  var CONTEXT = PAGE === 'lab' ? 'lab' : 'lesson';
  var BASE = body.getAttribute('data-base') || '';
  var ROOT = body.getAttribute('data-root') || '';
  var API = String(CFG.api || '').replace(/\/+$/, '');
  var CLIENT_ID = String(CFG.clientId || '');
  var CONFIGURED = !!(API && CLIENT_ID);
  var SCOPES = ['api://' + CLIENT_ID + '/Tutor.Ask'];
  var AUTHORITY = 'https://login.microsoftonline.com/common';
  var MSAL_SRC = BASE + 'assets/vendor/msal-browser.min.js';
  var INFO = ROOT + 'tutor.html';
  var MAX = 1000, ASK_MS = 90000, CALL_MS = 20000, PROGRESS_KEY = 'azlunch.v1';
  var SITE = null;
  try { SITE = new URL(String(CFG.pages || '').replace(/\/*$/, '/')); } catch (e) { SITE = null; }

  var ERR = {
    bad_request: 'errBadRequest', too_long: 'errTooLong', sign_in_required: 'errSignInRequired',
    not_in_pilot: 'errNotInPilot', not_invited: 'errNotInvited', blocked: 'errBlocked', busy: 'errBusy',
    content_filtered: 'errFiltered', daily_limit_reached: 'errLimit', paused: 'errPaused', ai_unavailable: 'errAi',
    network: 'errNetwork', timeout: 'errTimeout'
  };
  var STATUS_CODES = { 400: 'bad_request', 401: 'sign_in_required', 409: 'busy', 422: 'content_filtered', 429: 'daily_limit_reached' };

  var st = {
    open: false, started: false, busy: false, signingIn: false, account: null, pca: null, msal: null,
    left: null, limit: null, isOpen: null, statusAt: 0, refresh: false
  };

  /* --------------------------------------------------------------- helpers */
  function t(k, v) {
    var s = UI[k] == null ? k : String(UI[k]);
    return v ? s.replace(/\{(\w+)\}/g, function (m, x) { return v[x] != null ? String(v[x]) : m; }) : s;
  }
  function has(obj, k) { return Object.prototype.hasOwnProperty.call(obj, k); }
  function el(tag, attrs, kids) {
    var node = doc.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) {
      var v = attrs[k];
      if (v == null || v === false) return;
      if (k === 'text') node.textContent = String(v);
      else if (k === 'class') node.className = v;
      else node.setAttribute(k, v === true ? '' : String(v));
    });
    (kids || []).forEach(function (c) {
      if (c != null) node.appendChild(typeof c === 'string' ? doc.createTextNode(c) : c);
    });
    return node;
  }
  function esc(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }
  function unesc(s) {
    return String(s).replace(/&(amp|lt|gt|quot|#39);/g, function (m, x) {
      return { amp: '&', lt: '<', gt: '>', quot: '"', '#39': "'" }[x];
    });
  }
  function num(x) { return typeof x === 'number' && isFinite(x) ? Math.max(0, Math.floor(x)) : null; }
  function progress() {
    try {
      var s = JSON.parse(localStorage.getItem(PROGRESS_KEY) || 'null');
      var done = s && s.done && typeof s.done === 'object' ? s.done : {};
      return Object.keys(done).filter(function (k) { return done[k] && /^\d{2}$/.test(k); }).sort().slice(0, 40);
    } catch (e) { return []; }
  }

  /* ---------------------------------------------- safe Markdown for answers
     Everything is HTML-escaped first; only this small subset becomes markup: paragraphs, line
     breaks, **bold**, *italic*, `code`, fenced code blocks, - and 1. lists, and links to
     https://learn.microsoft.com or this course site (new tab, rel="noopener noreferrer"). */
  function safeUrl(raw) {
    var u;
    try { u = new URL(unesc(raw)); } catch (e) { return ''; }
    if (u.protocol !== 'https:' || u.username || u.password || u.port) return '';
    if (u.hostname.toLowerCase() === 'learn.microsoft.com') return u.href;
    if (SITE && u.origin === SITE.origin && (u.pathname + '/').indexOf(SITE.pathname) === 0) return u.href;
    return '';
  }
  function link(href, labelHtml) {
    return '<a href="' + esc(href) + '" target="_blank" rel="noopener noreferrer">' + labelHtml + '</a>';
  }
  function emphasis(s) {
    s = s.replace(/\*\*([^\s*](?:[^*\n]*[^\s*])?)\*\*/g, '<strong>$1</strong>');
    return s.replace(/(^|[^\w*])\*([^\s*](?:[^*\n]*[^\s*])?)\*(?!\w)/g, '$1<em>$2</em>');
  }
  function inline(s) {
    var slots = [];
    function keep(h) { slots.push(h); return '\uE000' + (slots.length - 1) + '\uE001'; }
    s = s.replace(/`([^`\n]+)`/g, function (m, c) { return keep('<code>' + c + '</code>'); });
    s = s.replace(/\[([^\]\n]+)\]\(\s*([^\s()]+(?:\([^\s()]*\)[^\s()]*)*)\s*\)/g, function (m, label, url) {
      var href = safeUrl(url);
      return href ? keep(link(href, emphasis(label))) : label;
    });
    s = s.replace(/https:\/\/[^\s`\uE000\uE001]+/g, function (m) {
      var url = m.split(/&(?:quot|#39|lt|gt);/)[0];
      var rest = m.slice(url.length);
      var trail = url.match(/[.,;:!?*\]]+$/);
      if (trail) { url = url.slice(0, -trail[0].length); rest = trail[0] + rest; }
      while (/\)$/.test(url) && (url.match(/\)/g) || []).length > (url.match(/\(/g) || []).length) {
        url = url.slice(0, -1); rest = ')' + rest;
      }
      var href = safeUrl(url);
      return href ? keep(link(href, url)) + rest : m;
    });
    s = emphasis(s);
    for (var i = 0; i < 3 && s.indexOf('\uE000') !== -1; i++) {
      s = s.replace(/\uE000(\d+)\uE001/g, function (m, d) { return slots[+d] || ''; });
    }
    return s;
  }
  function renderMarkdown(src) {
    var text = esc(String(src == null ? '' : src).replace(/\r\n?/g, '\n').replace(/[\uE000\uE001]/g, ''));
    var lines = text.split('\n'), out = [], para = [], lists = [], blank = false;
    function flush() { if (para.length) { out.push('<p>' + para.map(inline).join('<br>') + '</p>'); para = []; } }
    function closeLists(depth) { while (lists.length > depth) out.push('</li></' + lists.pop().type + '>'); }
    function indentOf(line) { return line.match(/^ */)[0].length; }
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].replace(/\t/g, '    ');
      var fence = line.match(/^( *)(`{3,}|~{3,})\s*([\w+#.-]{0,20})/);
      if (fence) {
        flush();
        var ind = fence[1].length, mark = fence[2], code = [];
        if (!(lists.length && ind >= 2)) closeLists(0);
        for (i++; i < lines.length; i++) {
          var cl = lines[i];
          if (cl.trim().indexOf(mark) === 0 && /^\s*(`+|~+)\s*$/.test(cl)) break;
          code.push(cl.slice(Math.min(ind, indentOf(cl))));
        }
        out.push('<div class="tutor-code"><div class="tutor-code-head"><span>' + (fence[3] || 'code') +
          '</span><button type="button" class="tutor-copy">' + esc(t('copy')) + '</button></div><pre><code>' +
          code.join('\n') + '</code></pre></div>');
        blank = false;
        continue;
      }
      if (!line.trim()) { flush(); blank = true; continue; }
      var item = line.match(/^( *)([-*+]|\d{1,3}[.)])\s+(.*)$/);
      if (item && !/^\s*([-*_])(\s*\1){2,}\s*$/.test(line)) {
        flush();
        var lead = item[1].length, type = /\d/.test(item[2]) ? 'ol' : 'ul';
        while (lists.length > 1 && lead < lists[lists.length - 1].indent) closeLists(lists.length - 1);
        var top = lists[lists.length - 1];
        if (!top || lead >= top.indent + 2) {
          var start = type === 'ol' ? parseInt(item[2], 10) : 1;
          out.push('<' + type + (start > 1 ? ' start="' + start + '"' : '') + '><li>' + inline(item[3]));
          lists.push({ type: type, indent: lead });
        } else if (top.type !== type) {
          out.push('</li></' + lists.pop().type + '><' + type + '><li>' + inline(item[3]));
          lists.push({ type: type, indent: lead });
        } else {
          out.push('</li><li>' + inline(item[3]));
        }
        blank = false;
        continue;
      }
      var head = line.match(/^\s{0,3}#{1,6}\s+(.*?)\s*#*\s*$/);
      var rule = /^\s*([-*_])(\s*\1){2,}\s*$/.test(line) || /^\s*\|?[\s:|-]*-{3,}[\s:|-]*$/.test(line);
      if (lists.length && !head && !rule && (indentOf(line) >= 2 || !blank)) {
        out.push('<br>' + inline(line.trim()));
        blank = false;
        continue;
      }
      closeLists(0);
      blank = false;
      if (rule) { flush(); continue; }
      if (head) { flush(); out.push('<p class="tutor-h"><strong>' + inline(head[1]) + '</strong></p>'); continue; }
      para.push(line.replace(/^\s*(?:&gt;\s?)+/, '').trim());
    }
    flush();
    closeLists(0);
    return out.join('');
  }

  /* ------------------------------------------------------------------ build UI */
  var launcher = el('button', {
    type: 'button', 'class': 'tutor-launcher', 'aria-haspopup': 'dialog', 'aria-expanded': 'false', 'aria-controls': 'tutor-panel'
  }, [el('span', { 'class': 'tutor-launcher-icon', 'aria-hidden': 'true', text: '💬' }), el('span', { text: t('launch') })]);

  var closeBtn = el('button', { type: 'button', 'class': 'tutor-close', 'aria-label': t('close'), title: t('close'), text: '✕' });
  var statusText = el('span', { 'class': 'tutor-status-text', text: CONFIGURED ? t('statusLoading') : '' });
  var statusBox = el('p', { 'class': 'tutor-status' }, [statusText, el('span', { 'class': 'tutor-reset', text: t('statusReset') })]);
  var cfgNote = el('p', { 'class': 'tutor-note', text: t('notConfigured') });
  var signInLabel = el('span', { text: t('signIn') });
  var signInBtn = el('button', { type: 'button', 'class': 'btn btn-sm tutor-signin' }, [
    el('span', { 'class': 'tutor-ms', 'aria-hidden': 'true' }, [el('i'), el('i'), el('i'), el('i')]), signInLabel
  ]);
  var whoEl = el('span', { 'class': 'tutor-who' });
  var signOutBtn = el('button', { type: 'button', 'class': 'tutor-linkbtn', text: t('signOut') });
  var accountBox = el('div', { 'class': 'tutor-account' }, [signInBtn, whoEl, signOutBtn]);
  var notice = el('div', { 'class': 'tutor-notice', role: 'status', 'aria-live': 'polite' });
  var emptyNote = el('p', { 'class': 'tutor-empty', text: t('empty') });
  var log = el('div', { 'class': 'tutor-log', role: 'log', 'aria-live': 'polite', 'aria-label': t('logLabel'), tabindex: '0' }, [emptyNote]);
  var ta = el('textarea', {
    id: 'tutor-q', 'class': 'tutor-input', rows: '3', maxlength: String(MAX), 'aria-describedby': 'tutor-count tutor-hint',
    placeholder: t(CONTEXT === 'lab' ? 'placeholderLab' : 'placeholderLesson')
  });
  var counter = el('span', { id: 'tutor-count', 'class': 'tutor-count' });
  var askBtn = el('button', { type: 'submit', 'class': 'btn btn-primary btn-sm tutor-ask', text: t('ask') });
  var form = el('form', { 'class': 'tutor-form', novalidate: true }, [
    el('label', { 'for': 'tutor-q', 'class': 'sr-only', text: t('label') }),
    ta,
    el('div', { 'class': 'tutor-row' }, [counter, askBtn]),
    el('p', { id: 'tutor-hint', 'class': 'tutor-hint', text: t('hint') })
  ]);
  var forgetBtn = el('button', { type: 'button', 'class': 'tutor-linkbtn', text: t('forget') });
  var panel = el('div', { id: 'tutor-panel', 'class': 'tutor-panel', role: 'dialog', 'aria-modal': 'false', 'aria-labelledby': 'tutor-title' }, [
    el('div', { 'class': 'tutor-head' }, [
      el('h2', { id: 'tutor-title', 'class': 'tutor-title' }, [t('title') + ' ', el('span', { 'class': 'tutor-badge', text: t('badge') })]),
      closeBtn
    ]),
    el('div', { 'class': 'tutor-meta' }, [statusBox, cfgNote, accountBox, notice]),
    log,
    form,
    el('div', { 'class': 'tutor-foot' }, [
      el('p', { text: t('footWrong') }),
      el('p', { text: t('footOfficial') }),
      el('p', { 'class': 'tutor-links' }, [
        el('a', { href: INFO, target: '_blank', rel: 'noopener' }, [t('privacy'), el('span', { 'class': 'sr-only', text: ' ' + t('newTab') })]),
        el('span', { 'aria-hidden': 'true', text: '·' }),
        forgetBtn
      ])
    ])
  ]);
  body.appendChild(launcher);
  body.appendChild(panel);

  /* ------------------------------------------------------------- UI state */
  function updateCounter() {
    var n = ta.value.length;
    counter.textContent = t('counter', { n: n, max: MAX });
    counter.classList.toggle('near', n > MAX - 100);
  }
  function updateControls() {
    askBtn.disabled = !CONFIGURED || st.busy;
    askBtn.textContent = st.busy ? t('asking') : t('ask');
    ta.disabled = !CONFIGURED;
    forgetBtn.disabled = !CONFIGURED;
    signInBtn.disabled = !CONFIGURED || st.signingIn;
    signInLabel.textContent = st.signingIn ? t('signingIn') : t('signIn');
  }
  function setAccount(acc) {
    st.account = acc || null;
    signInBtn.hidden = !!st.account;
    whoEl.hidden = signOutBtn.hidden = !st.account;
    whoEl.textContent = st.account ? t('signedInAs', { name: st.account.name || st.account.username || '' }) : '';
  }
  function renderStatus() {
    if (!CONFIGURED) return;
    if (st.isOpen === false && st.left !== 0) statusText.textContent = t('statusPaused');
    else if (st.left != null && st.limit != null) statusText.textContent = t('status', { left: st.left, limit: st.limit });
  }
  function updateCounts(d) {
    if (!d || typeof d !== 'object') return;
    var left = num(d.left), limit = num(d.limit);
    if (left != null) st.left = left;
    if (limit != null) st.limit = limit;
    if (typeof d.open === 'boolean') st.isOpen = d.open;
    renderStatus();
  }
  function messageNodes(m) {
    var nodes = [t(m.key, m.vars)];
    if (m.link) {
      nodes.push(' ', el('a', { href: INFO + '#it', target: '_blank', rel: 'noopener' },
        [t('itLink'), el('span', { 'class': 'sr-only', text: ' ' + t('newTab') })]));
    }
    return nodes;
  }
  function showNotice(m, isError) {
    notice.textContent = '';
    notice.classList.toggle('is-error', !!isError);
    notice.appendChild(el('p', {}, messageNodes(m)));
  }
  function clearNotice() { notice.textContent = ''; notice.classList.remove('is-error'); }
  function scrollLog(toEl) {
    log.scrollTop = toEl ? Math.max(0, toEl.offsetTop - 8) : log.scrollHeight;
  }
  function addMessage(node, top) {
    if (emptyNote.parentNode) emptyNote.parentNode.removeChild(emptyNote);
    log.appendChild(node);
    scrollLog(top ? node : null);
    return node;
  }
  function addQuestion(q) {
    addMessage(el('div', { 'class': 'tutor-msg tutor-q' }, [el('span', { 'class': 'sr-only', text: t('you') + ': ' }), el('p', { text: q })]));
  }
  function addAnswer(md) {
    var box = el('div', { 'class': 'tutor-md' });
    box.innerHTML = renderMarkdown(md); // all model text is HTML-escaped inside renderMarkdown
    addMessage(el('div', { 'class': 'tutor-msg tutor-a' }, [el('span', { 'class': 'sr-only', text: t('tutorName') + ': ' }), box]), true);
  }
  function addSystem(m) { addMessage(el('div', { 'class': 'tutor-msg tutor-sys' }, [el('p', {}, messageNodes(m))])); }
  function addPending() {
    return addMessage(el('div', { 'class': 'tutor-msg tutor-a tutor-pending' }, [
      el('span', { 'class': 'tutor-dots', 'aria-hidden': 'true' }, [el('i'), el('i'), el('i')]),
      el('span', { text: t('thinking') })
    ]));
  }
  function clearLog() { log.textContent = ''; log.appendChild(emptyNote); }

  /* -------------------------------------------------------- open and close */
  function openPanel() {
    if (st.open) return;
    st.open = true;
    panel.classList.add('open');
    body.classList.add('tutor-is-open');
    launcher.setAttribute('aria-expanded', 'true');
    if (!st.started) { st.started = true; start(); }
    else if (CONFIGURED && Date.now() - st.statusAt > 60000) loadStatus();
    var phone = window.matchMedia && window.matchMedia('(max-width: 600px)').matches; // no surprise keyboard
    setTimeout(function () { (CONFIGURED && !phone ? ta : closeBtn).focus(); }, 30);
  }
  function closePanel(returnFocus) {
    if (!st.open) return;
    st.open = false;
    panel.classList.remove('open');
    body.classList.remove('tutor-is-open');
    launcher.setAttribute('aria-expanded', 'false');
    if (returnFocus) launcher.focus();
  }
  function start() {
    if (!CONFIGURED) return;
    loadStatus();
    loadMsal().then(restoreAccount, function (e) { showNotice(signInError(e), true); });
  }

  /* ------------------------------------------------------------- network */
  function request(url, opts, ms) {
    var ctrl = typeof AbortController === 'function' ? new AbortController() : null;
    var timer = setTimeout(function () { if (ctrl) ctrl.abort(); }, ms);
    var init = { method: opts.method || 'GET', headers: opts.headers || {}, mode: 'cors', credentials: 'omit', cache: 'no-store' };
    if (opts.body != null) init.body = opts.body;
    if (ctrl) init.signal = ctrl.signal;
    return fetch(url, init).then(function (res) {
      return res.text().then(function (txt) {
        var data = null;
        try { data = txt ? JSON.parse(txt) : null; } catch (e) { data = null; }
        return { ok: res.ok, status: res.status, data: data && typeof data === 'object' ? data : null };
      });
    }).then(function (r) { clearTimeout(timer); return r; }, function (e) {
      clearTimeout(timer);
      var err = new Error('request failed');
      err.kind = e && e.name === 'AbortError' ? 'timeout' : 'network';
      throw err;
    });
  }
  function apiCode(r) {
    var code = r.data && typeof r.data.error === 'string' ? r.data.error : '';
    return code || STATUS_CODES[r.status] || 'unknown';
  }
  function errKey(code) { return has(ERR, code) ? ERR[code] : 'errUnknown'; }
  function apiMessage(code) { return { key: errKey(code), link: code === 'not_in_pilot' }; }
  function noteCode(code, data) {
    updateCounts(data);
    if (code === 'daily_limit_reached') { st.left = 0; renderStatus(); }
    if (code === 'paused') { st.isOpen = false; renderStatus(); }
    if (code === 'sign_in_required') st.refresh = true;
  }
  function loadStatus() {
    st.statusAt = Date.now();
    request(API + '/status', { method: 'GET' }, CALL_MS).then(function (r) {
      if (r.ok && r.data) {
        updateCounts(r.data);
        if (st.left == null || st.limit == null) statusText.textContent = st.isOpen === false ? t('statusPaused') : t('statusError');
      } else {
        statusText.textContent = t('statusError');
      }
    }, function () { statusText.textContent = t('statusError'); });
  }

  /* ------------------------------------------------------------ sign-in */
  function loadScript(src) {
    return new Promise(function (resolve, reject) {
      var s = doc.createElement('script');
      s.src = src;
      s.async = true;
      s.onload = function () { resolve(); };
      s.onerror = function () { reject(msalLoadError()); };
      doc.head.appendChild(s);
    });
  }
  function msalLoadError() { var e = new Error('msal_load'); e.errorCode = 'msal_load'; return e; }
  async function createPca() {
    var M = window.msal;
    if (!M || typeof M.PublicClientApplication !== 'function') throw msalLoadError();
    var redirect = new URL(BASE + 'auth/redirect.html', location.href).href;
    var cfg = {
      auth: { clientId: CLIENT_ID, authority: AUTHORITY, redirectUri: redirect, postLogoutRedirectUri: redirect },
      cache: { cacheLocation: 'localStorage' }
    };
    var pca;
    if (typeof M.PublicClientApplication.createPublicClientApplication === 'function') {
      pca = await M.PublicClientApplication.createPublicClientApplication(cfg);
    } else {
      pca = new M.PublicClientApplication(cfg);
      if (typeof pca.initialize === 'function') await pca.initialize();
    }
    st.pca = pca;
    return pca;
  }
  function loadMsal() {
    if (!st.msal) {
      st.msal = (window.msal ? Promise.resolve() : loadScript(MSAL_SRC)).then(createPca);
      st.msal.catch(function () { st.msal = null; });
    }
    return st.msal;
  }
  function pickAccount(list) {
    return (list || []).filter(function (a) {
      var c = a && a.idTokenClaims;
      return a && (!c || !c.aud || c.aud === CLIENT_ID);
    })[0] || null;
  }
  function restoreAccount(pca) {
    var acc = null;
    try {
      acc = pca.getActiveAccount() || pickAccount(pca.getAllAccounts());
      if (acc) pca.setActiveAccount(acc);
    } catch (e) { acc = null; }
    setAccount(acc);
  }
  function signInError(e) {
    var code = String((e && (e.errorCode || e.error)) || '');
    var text = [code, e && e.errorMessage, e && e.message, e && e.subError].join(' ').toLowerCase();
    if (/aadsts90094|aadsts65001|aadsts90095|admin_consent|consent_required|needs admin approval/.test(text)) return { key: 'errAdmin', link: true };
    if (/popup_window_error|empty_window_error|popup.{0,40}(blocked|closed)/.test(text)) return { key: 'errPopup' };
    if (/user_cancelled|user_canceled|aadsts65004|cancel/.test(text)) return { key: 'errCancelled' };
    if (/interaction_in_progress/.test(text)) return { key: 'errInProgress' };
    if (code === 'msal_load') return { key: 'errMsalLoad' };
    return { key: 'errSignIn' };
  }
  function needsInteraction(e) {
    var M = window.msal;
    if (!e) return false;
    if (M && typeof M.InteractionRequiredAuthError === 'function' && e instanceof M.InteractionRequiredAuthError) return true;
    return e.name === 'InteractionRequiredAuthError';
  }
  async function signIn() {
    if (!CONFIGURED || st.signingIn) return;
    clearNotice();
    st.signingIn = true;
    updateControls();
    try {
      var pca = await loadMsal();
      var res = await pca.loginPopup({ scopes: SCOPES, prompt: 'select_account' });
      var acc = (res && res.account) || null;
      if (acc) pca.setActiveAccount(acc);
      setAccount(acc);
    } catch (e) {
      showNotice(signInError(e), true);
    } finally {
      st.signingIn = false;
      updateControls();
    }
    (st.account ? ta : signInBtn).focus();
  }
  function dropAccount(acc) {
    // Fallback for MSAL builds without clearCache(): remove only this account's entries from this site's storage.
    var id = String((acc && acc.homeAccountId) || '').toLowerCase();
    if (!id) return;
    try {
      for (var i = localStorage.length - 1; i >= 0; i--) {
        var k = localStorage.key(i);
        if (k && k.toLowerCase().indexOf(id) !== -1) localStorage.removeItem(k);
      }
    } catch (e) { /* storage blocked */ }
  }
  async function signOut() {
    var pca = st.pca, acc = st.account;
    clearNotice();
    if (pca && acc) {
      try {
        if (typeof pca.clearCache === 'function') await pca.clearCache({ account: acc });
        else dropAccount(acc);
      } catch (e) { dropAccount(acc); }
      try { pca.setActiveAccount(null); } catch (e) { /* older MSAL */ }
    }
    setAccount(null);
    showNotice({ key: 'signedOut' });
    signInBtn.focus();
  }
  async function getToken() {
    var pca = await loadMsal();
    var acc = st.account;
    if (!acc) { var none = new Error('no_account'); none.errorCode = 'no_account'; throw none; }
    var req = { scopes: SCOPES, account: acc };
    if (st.refresh) req.forceRefresh = true;
    var res;
    try {
      res = await pca.acquireTokenSilent(req);
    } catch (e) {
      if (!needsInteraction(e)) throw e;
      res = await pca.acquireTokenPopup({ scopes: SCOPES, account: acc });
      if (res && res.account) { pca.setActiveAccount(res.account); setAccount(res.account); }
    }
    st.refresh = false;
    return res.accessToken;
  }

  /* ----------------------------------------------------- ask and forget */
  async function ask(ev) {
    if (ev) ev.preventDefault();
    if (st.busy || !CONFIGURED) return;
    var q = ta.value.replace(/\r\n?/g, '\n').trim().slice(0, MAX);
    if (!q) { ta.focus(); return; }
    st.busy = true;
    updateControls();
    var pending = null;
    try {
      if (!st.account && st.msal) { try { await st.msal; } catch (e) { /* reported when the panel opened */ } }
      if (!st.account) { showNotice({ key: 'needSignIn' }, true); signInBtn.focus(); return; }
      clearNotice();
      addQuestion(q);
      ta.value = '';
      updateCounter();
      pending = addPending();
      var outcome;
      try {
        var token = await getToken();
        var r = await request(API + '/ask', {
          method: 'POST',
          headers: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
          body: JSON.stringify({ lunch: LUNCH, lang: LANG, context: CONTEXT, question: q, progress: progress() })
        }, ASK_MS);
        if (r.ok && r.data && typeof r.data.answer === 'string') {
          st.isOpen = true;
          updateCounts(r.data);
          outcome = { answer: r.data.answer };
        } else {
          var code = apiCode(r);
          noteCode(code, r.data);
          outcome = { message: apiMessage(code) };
        }
      } catch (e) {
        outcome = { message: e && e.kind ? apiMessage(e.kind) : signInError(e) };
      }
      if (pending.parentNode) pending.parentNode.removeChild(pending);
      if (outcome.answer != null) addAnswer(outcome.answer);
      else {
        addSystem(outcome.message);
        if (!ta.value) { ta.value = q; updateCounter(); }
      }
    } finally {
      if (pending && pending.parentNode) pending.parentNode.removeChild(pending);
      st.busy = false;
      updateControls();
    }
  }
  async function forget() {
    if (!CONFIGURED) return;
    clearNotice();
    if (!st.account) { showNotice({ key: 'forgetSignIn' }, true); signInBtn.focus(); return; }
    if (!window.confirm(t('forgetConfirm'))) return;
    forgetBtn.disabled = true;
    try {
      var token = await getToken();
      var r = await request(API + '/forget', {
        method: 'POST',
        headers: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
        body: '{}'
      }, CALL_MS);
      if (r.ok) {
        var n = r.data ? num(r.data.deleted) : null;
        clearLog();
        showNotice({ key: 'forgetDone', vars: { n: n == null ? 0 : n } });
      } else {
        var code = apiCode(r);
        noteCode(code, r.data);
        showNotice(apiMessage(code), true);
      }
    } catch (e) {
      showNotice(e && e.kind ? apiMessage(e.kind) : signInError(e), true);
    } finally {
      updateControls();
    }
  }
  function copyText(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) return navigator.clipboard.writeText(text);
    return new Promise(function (resolve, reject) {
      var area = el('textarea', { 'class': 'sr-only', readonly: true });
      area.value = text;
      body.appendChild(area);
      area.select();
      var ok = false;
      try { ok = doc.execCommand('copy'); } catch (e) { ok = false; }
      body.removeChild(area);
      if (ok) resolve(); else reject(new Error('copy'));
    });
  }

  /* -------------------------------------------------------------- events */
  launcher.addEventListener('click', openPanel);
  closeBtn.addEventListener('click', function () { closePanel(true); });
  doc.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape' || !st.open || e.isComposing) return;
    if (doc.querySelector('.modal.open')) return; // the site's own dialog closes first
    closePanel(panel.contains(doc.activeElement));
  });
  form.addEventListener('submit', ask);
  ta.addEventListener('input', updateCounter);
  ta.addEventListener('keydown', function (e) {
    if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) { e.preventDefault(); ask(); }
  });
  signInBtn.addEventListener('click', signIn);
  signOutBtn.addEventListener('click', signOut);
  forgetBtn.addEventListener('click', forget);
  log.addEventListener('click', function (e) {
    var btn = e.target && e.target.closest ? e.target.closest('.tutor-copy') : null;
    if (!btn || !log.contains(btn)) return;
    var code = btn.parentNode && btn.parentNode.parentNode ? btn.parentNode.parentNode.querySelector('code') : null;
    copyText(code ? code.textContent : '').then(function () {
      btn.textContent = t('copied');
      setTimeout(function () { btn.textContent = t('copy'); }, 1600);
    }, function () { /* clipboard blocked: the code stays selectable */ });
  });

  /* ------------------------------------------------------------ initial */
  cfgNote.hidden = CONFIGURED;
  statusBox.hidden = !CONFIGURED;
  accountBox.hidden = !CONFIGURED;
  setAccount(null);
  updateCounter();
  updateControls();
})();

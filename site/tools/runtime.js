/* Verbind&GO — kleine runtime voor de standalone export.
   Rendert de templates (sc-if, sc-for, dc-import, {{holes}}) zonder de Claude Design-omgeving. */
(function () {
  'use strict';
  var SVG_NS = 'http://www.w3.org/2000/svg';
  var HOLE_RE = /\{\{\s*([^}]+?)\s*\}\}/g;
  var registry = {};      // name -> { tpl: Element (XML), Component, props }
  var instances = {};     // key -> instance
  var mounted = {};       // key -> true once componentDidMount ran
  var rootName = null, rootEl = null, rafId = 0;

  function DCLogic(props) { this.props = props || {}; this.state = {}; }
  DCLogic.prototype.setState = function (patch) {
    if (typeof patch === 'function') patch = patch(this.state);
    this.state = Object.assign({}, this.state, patch);
    schedule();
  };
  DCLogic.prototype.forceUpdate = function () { schedule(); };

  function schedule() {
    if (rafId) return;
    rafId = requestAnimationFrame(function () { rafId = 0; renderRoot(); });
  }

  function parseTemplate(xml) {
    var doc = new DOMParser().parseFromString('<dc-root>' + xml + '</dc-root>', 'application/xml');
    var err = doc.getElementsByTagName('parsererror')[0];
    if (err) { console.error('Template fout:', err.textContent); }
    return doc.documentElement;
  }

  function register(name, def) {
    var Component = new Function('DCLogic', def.src + '\nreturn Component;')(DCLogic);
    var defaults = {};
    Object.keys(def.props || {}).forEach(function (k) {
      if (k.charAt(0) !== '$' && def.props[k] && 'default' in def.props[k]) defaults[k] = def.props[k]['default'];
    });
    registry[name] = { tpl: parseTemplate(def.tpl), Component: Component, defaults: defaults };
  }

  function resolve(expr, scope) {
    expr = expr.trim();
    if (expr === 'true') return true;
    if (expr === 'false') return false;
    if (expr === 'null') return null;
    if (/^-?\d+(\.\d+)?$/.test(expr)) return Number(expr);
    if (/^'.*'$/.test(expr) || /^".*"$/.test(expr)) return expr.slice(1, -1);
    var parts = expr.split('.');
    var cur = scope;
    for (var i = 0; i < parts.length; i++) {
      if (cur == null) return undefined;
      cur = cur[parts[i]];
    }
    return cur;
  }

  function evalAttr(value, scope) {
    var m = value.match(/^\{\{\s*([^}]+?)\s*\}\}$/);
    if (m) return { raw: true, value: resolve(m[1], scope) };
    if (value.indexOf('{{') === -1) return { raw: false, value: value };
    return { raw: false, value: value.replace(HOLE_RE, function (_, e) { var v = resolve(e, scope); return v == null ? '' : String(v); }) };
  }

  function eventName(attr, el) {
    var n = attr.slice(2).toLowerCase();
    if (n === 'change') {
      var tag = el.tagName.toLowerCase();
      var type = (el.getAttribute('type') || 'text').toLowerCase();
      if (tag === 'select' || type === 'checkbox' || type === 'radio' || type === 'file') return 'change';
      return 'input';
    }
    return n;
  }

  var PROP_ATTRS = { value: 1, checked: 1, disabled: 1, selected: 1, readonly: 1 };

  function build(node, scope, inSvg, ctx, out) {
    if (node.nodeType === 3 || node.nodeType === 4) {
      var text = node.nodeValue;
      if (text.indexOf('{{') !== -1) text = text.replace(HOLE_RE, function (_, e) { var v = resolve(e, scope); return v == null ? '' : String(v); });
      out.push(document.createTextNode(text));
      return;
    }
    if (node.nodeType !== 1) return;
    var tag = node.nodeName;
    var lower = tag.toLowerCase();

    if (lower === 'sc-if') {
      var cond = evalAttr(node.getAttribute('value') || '', scope).value;
      if (cond) for (var c = node.firstChild; c; c = c.nextSibling) build(c, scope, inSvg, ctx, out);
      return;
    }
    if (lower === 'sc-for') {
      var list = evalAttr(node.getAttribute('list') || '', scope).value || [];
      var as = node.getAttribute('as') || 'item';
      for (var i = 0; i < list.length; i++) {
        var s = Object.create(scope); s[as] = list[i]; s.$index = i;
        for (var c2 = node.firstChild; c2; c2 = c2.nextSibling) build(c2, s, inSvg, ctx, out);
      }
      return;
    }
    if (lower === 'dc-import') {
      var name = node.getAttribute('name');
      var props = {};
      for (var a = 0; a < node.attributes.length; a++) {
        var at = node.attributes[a];
        if (at.name === 'name' || at.name.indexOf('hint-') === 0) continue;
        var camel = at.name.replace(/-([a-z])/g, function (_, ch) { return ch.toUpperCase(); });
        props[camel] = evalAttr(at.value, scope).value;
      }
      ctx.importCount[name] = (ctx.importCount[name] || 0) + 1;
      var key = ctx.key + '>' + name + '#' + ctx.importCount[name];
      var frag = renderComponent(name, props, key);
      for (var k = 0; k < frag.length; k++) out.push(frag[k]);
      return;
    }

    var svg = inSvg || lower === 'svg';
    var el = svg ? document.createElementNS(SVG_NS, tag) : document.createElement(tag);
    var handlers = {}, propsToSet = {};
    for (var j = 0; j < node.attributes.length; j++) {
      var attr = node.attributes[j];
      var an = attr.name;
      if (an.indexOf('hint-') === 0) continue;
      if (/^on[A-Z]/.test(an) || (/^on[a-z]/.test(an) && an !== 'on')) {
        var fn = evalAttr(attr.value, scope).value;
        if (typeof fn === 'function') handlers[eventName(an, el)] = fn;
        continue;
      }
      var r = evalAttr(attr.value, scope);
      var anl = an.toLowerCase();
      if (PROP_ATTRS[anl]) {
        propsToSet[anl] = r.value;
        if (r.raw && (r.value === false || r.value == null)) continue;
        if (anl === 'value') { el.setAttribute('value', r.value == null ? '' : String(r.value)); continue; }
        el.setAttribute(an, r.raw ? '' : String(r.value));
        continue;
      }
      if (r.raw && (r.value === undefined || r.value === null || r.value === false)) continue;
      el.setAttribute(an, String(r.value));
    }
    el.__dcH = handlers;
    el.__dcP = propsToSet;
    var kids = [];
    for (var c3 = node.firstChild; c3; c3 = c3.nextSibling) build(c3, scope, svg, ctx, kids);
    for (var q = 0; q < kids.length; q++) el.appendChild(kids[q]);
    out.push(el);
  }

  function renderComponent(name, props, key) {
    var def = registry[name];
    if (!def) { console.error('Onbekend component', name); return []; }
    var inst = instances[key];
    var fullProps = Object.assign({}, def.defaults, props);
    if (!inst) { inst = instances[key] = new def.Component(fullProps); inst.__key = key; }
    inst.props = fullProps;
    var vals = inst.renderVals ? (inst.renderVals() || {}) : {};
    var ctx = { key: key, importCount: {} };
    var out = [];
    for (var c = def.tpl.firstChild; c; c = c.nextSibling) build(c, vals, false, ctx, out);
    return out;
  }

  /* ---- morph: hergebruik bestaande DOM zodat animaties en focus blijven ---- */
  function applyProps(el) {
    var p = el.__dcP || {};
    if ('value' in p) {
      var v = p.value == null ? '' : String(p.value);
      if (el.tagName === 'SELECT') { if (el.value !== v) el.value = v; }
      else if (el.value !== v) el.value = v;
    }
    if ('checked' in p) el.checked = !!p.checked;
    if ('disabled' in p) el.disabled = !!p.disabled;
    if ('selected' in p) el.selected = !!p.selected;
  }
  function flush() {
    if (rafId) { cancelAnimationFrame(rafId); rafId = 0; renderRoot(); }
  }
  function bind(el) {
    var h = el.__dcH || {};
    var old = el.__dcBound || {};
    Object.keys(old).forEach(function (ev) { if (!h[ev]) { el.removeEventListener(ev, old[ev]); delete old[ev]; } });
    Object.keys(h).forEach(function (ev) {
      if (old[ev]) return;
      var wrapper = function (e) {
        var keep = (ev === 'input' || ev === 'change') && ('value' in el) ? { value: el.value, checked: el.checked } : null;
        flush();
        if (keep) { if (el.value !== keep.value) el.value = keep.value; if (el.checked !== keep.checked) el.checked = keep.checked; }
        var fn = el.__dcH && el.__dcH[ev]; if (fn) fn(e);
      };
      el.addEventListener(ev, wrapper); old[ev] = wrapper;
    });
    el.__dcBound = old;
  }
  function finalize(el) { // nieuw ingevoegde subtree: props + listeners zetten
    if (el.nodeType !== 1) return;
    applyProps(el); bind(el);
    for (var c = el.firstElementChild; c; c = c.nextElementSibling) finalize(c);
  }
  function morph(oldN, newN) {
    if (oldN.nodeType !== newN.nodeType || oldN.nodeName !== newN.nodeName) { finalize(newN); oldN.replaceWith(newN); return; }
    if (oldN.nodeType === 3) { if (oldN.nodeValue !== newN.nodeValue) oldN.nodeValue = newN.nodeValue; return; }
    if (oldN.nodeType !== 1) return;
    if (oldN.tagName !== 'CANVAS') {
      var i, a;
      for (i = oldN.attributes.length - 1; i >= 0; i--) {
        a = oldN.attributes[i];
        if (!newN.hasAttribute(a.name)) {
          if (a.name === 'open' && oldN.tagName === 'DETAILS') continue;
          oldN.removeAttribute(a.name);
        }
      }
      for (i = 0; i < newN.attributes.length; i++) {
        a = newN.attributes[i];
        if (oldN.getAttribute(a.name) !== a.value) oldN.setAttribute(a.name, a.value);
      }
    }
    oldN.__dcH = newN.__dcH; oldN.__dcP = newN.__dcP;
    var oc = Array.prototype.slice.call(oldN.childNodes), nc = Array.prototype.slice.call(newN.childNodes);
    var n = Math.max(oc.length, nc.length);
    for (var k = 0; k < n; k++) {
      if (!oc[k]) { finalize(nc[k]); oldN.appendChild(nc[k]); }
      else if (!nc[k]) { oldN.removeChild(oc[k]); }
      else morph(oc[k], nc[k]);
    }
    applyProps(oldN); bind(oldN);
  }

  function renderRoot() {
    var nodes = renderComponent(rootName, {}, 'root');
    var wrapper = document.createElement('div');
    for (var i = 0; i < nodes.length; i++) wrapper.appendChild(nodes[i]);
    if (!rootEl.firstChild) {
      for (var c = wrapper.firstElementChild; c; c = c.nextElementSibling) finalize(c);
      while (wrapper.firstChild) rootEl.appendChild(wrapper.firstChild);
    } else {
      var oc = Array.prototype.slice.call(rootEl.childNodes), nc = Array.prototype.slice.call(wrapper.childNodes);
      var n = Math.max(oc.length, nc.length);
      for (var k = 0; k < n; k++) {
        if (!oc[k]) { finalize(nc[k]); rootEl.appendChild(nc[k]); }
        else if (!nc[k]) rootEl.removeChild(oc[k]);
        else morph(oc[k], nc[k]);
      }
    }
    Object.keys(instances).forEach(function (key) {
      if (!mounted[key]) { mounted[key] = true; var inst = instances[key]; if (inst.componentDidMount) { try { inst.componentDidMount(); } catch (e) { console.error(e); } } }
    });
  }

  function mount(name, selector) {
    rootName = name; rootEl = document.querySelector(selector);
    renderRoot();
    setTimeout(function () { document.documentElement.setAttribute('data-settled', ''); }, 3000);
  }

  window.DC = { register: register, mount: mount, DCLogic: DCLogic };
})();

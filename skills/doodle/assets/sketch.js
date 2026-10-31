/* doodle sketch engine.
   Turns clean SVG paths into hand-drawn ones. Paste inline into the page, so the
   canvas stays one self-contained file.

   Usage: mark any <path> with data-sketch="1" (single stroke) or "2" (double,
   the default hand-drawn look), optionally data-amp="2.5" for wobble amplitude.
   Then call sketchify('#note') once, after the SVG is in the document.

   Every shape must be a <path>. getTotalLength is guaranteed on path in every
   browser, and is not on rect/ellipse/circle, so write boxes as M/L/Z and
   circles as two arcs rather than reaching for the convenience elements.

   If the script never runs the page still reads. It degrades to clean lines,
   which is the whole reason the geometry lives in markup and not in JS. */

function sketchify(root) {
  var NS = 'http://www.w3.org/2000/svg';
  var svg = typeof root === 'string' ? document.querySelector(root) : root;
  if (!svg) return;

  function prng(a) {
    return function () {
      a |= 0; a = a + 0x6D2B79F5 | 0;
      var t = Math.imul(a ^ a >>> 15, 1 | a);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }

  function wobble(el, seed, amp) {
    var len = el.getTotalLength();
    if (!len) return el.getAttribute('d');
    var n = Math.max(3, Math.min(220, Math.round(len / 13)));
    var r = prng(seed), pts = [], i, p;
    for (i = 0; i <= n; i++) {
      p = el.getPointAtLength(len * i / n);
      pts.push([p.x + (r() - 0.5) * amp * 2, p.y + (r() - 0.5) * amp * 2]);
    }
    var d = 'M' + pts[0][0].toFixed(1) + ',' + pts[0][1].toFixed(1);
    for (i = 1; i < n; i++) {
      var mx = (pts[i][0] + pts[i + 1][0]) / 2, my = (pts[i][1] + pts[i + 1][1]) / 2;
      d += ' Q' + pts[i][0].toFixed(1) + ',' + pts[i][1].toFixed(1) + ' ' + mx.toFixed(1) + ',' + my.toFixed(1);
    }
    return d + ' L' + pts[n][0].toFixed(1) + ',' + pts[n][1].toFixed(1);
  }

  var carry = ['stroke', 'stroke-width', 'stroke-linecap', 'stroke-linejoin',
               'stroke-dasharray', 'marker-end', 'marker-start', 'style', 'opacity', 'transform'];

  [].slice.call(svg.querySelectorAll('[data-sketch]')).forEach(function (el, idx) {
    var passes = parseInt(el.getAttribute('data-sketch'), 10) || 1;
    var amp = parseFloat(el.getAttribute('data-amp')) || 2.2;
    var g = document.createElementNS(NS, 'g');
    for (var pass = 0; pass < passes; pass++) {
      var np = document.createElementNS(NS, 'path');
      np.setAttribute('d', wobble(el, (idx + 3) * 9781 + pass * 3499, amp * (pass ? 1.3 : 1)));
      carry.forEach(function (a) { if (el.hasAttribute(a)) np.setAttribute(a, el.getAttribute(a)); });
      np.setAttribute('fill', pass === 0 ? (el.getAttribute('fill') || 'none') : 'none');
      if (passes > 1 && pass > 0) np.setAttribute('opacity', '0.5');
      g.appendChild(np);
    }
    el.parentNode.replaceChild(g, el);
  });
}

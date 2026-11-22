/* =============================================================================
   editable.js - turns a documentation page into an editable working document
   (test plans, coverage reports, issue reports, review forms).

   Markup conventions
     body[data-store-key]   localStorage key for this page (unique per page)
     body[data-export-name] base file name used by "Export HTML" / "Export CSV"
     [data-save]            element whose content is saved (needs an id)
                            - on a <table>: its <tbody> is saved
                            - on anything else: its innerHTML is saved
     table.edit             body cells become editable; a delete button is
                            added to every row and an "Add row" button below
     table.edit.fixed       editable cells, but no add / delete of rows
     td.ro                  cell stays read-only
     .editblock, span.field free-text areas that become editable
     table.weighted         rows with td.weight + td.score -> #score-total
     button[data-clone]     appends a copy of <template id=...> to the element
                            named by data-target (used for "Add report")
     .imgslot               image / diagram slot inside a [data-save] element:
                            "Insert diagram" embeds a PNG / SVG / JPG as a data URL
                            (so exported HTML is self-contained). data-slot = file
                            base name, body[data-deliv-base] = deliverables folder
                            seen from this page (used when an image is too large for
                            browser storage and is saved as a link diagrams/<name>.<ext>)

   Everything is stored in the browser (localStorage) automatically. Use
   "Export HTML" to keep a file copy (open it again to continue editing it).
   ============================================================================= */
(function () {
  "use strict";

  var body, storeKey, saveTimer = null, statusEl = null;

  function $(sel, root) { return (root || document).querySelector(sel); }
  function $all(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }

  // ------------------------------------------------------------- decoration --
  function decorateTable(tbl) {
    var fixed = tbl.classList.contains("fixed");
    var thead = tbl.tHead;
    if (!fixed && thead && thead.rows.length && !thead.rows[0].querySelector("th.ctl")) {
      var th = document.createElement("th");
      th.className = "ctl";
      th.title = "delete row";
      thead.rows[0].appendChild(th);
    }
    $all("tbody tr", tbl).forEach(function (tr) { decorateRow(tr, fixed); });
    if (!fixed && !(tbl.nextElementSibling && tbl.nextElementSibling.classList.contains("addrow"))) {
      var b = document.createElement("button");
      b.className = "addrow";
      b.type = "button";
      b.textContent = "+ Add row";
      b.addEventListener("click", function () { addRow(tbl); });
      tbl.parentNode.insertBefore(b, tbl.nextSibling);
    }
  }

  function decorateRow(tr, fixed) {
    Array.prototype.forEach.call(tr.cells, function (td) {
      if (td.classList.contains("ctl")) return;
      if (td.classList.contains("ro") || td.tagName === "TH") {
        td.removeAttribute("contenteditable");
      } else if (!td.querySelector("input")) {
        td.setAttribute("contenteditable", "true");
      }
    });
    if (!fixed && !tr.querySelector("td.ctl")) {
      var td = document.createElement("td");
      td.className = "ctl";
      td.innerHTML = '<button type="button" class="delrow" title="delete this row">&#x2715;</button>';
      tr.appendChild(td);
    }
  }

  function addRow(tbl) {
    var tb = tbl.tBodies[0];
    var cols = 0;
    if (tbl.tHead && tbl.tHead.rows.length) {
      cols = $all("th:not(.ctl)", tbl.tHead.rows[0]).length;
    } else if (tb.rows.length) {
      cols = $all("td:not(.ctl)", tb.rows[0]).length;
    }
    var tr = document.createElement("tr");
    for (var i = 0; i < cols; i++) tr.appendChild(document.createElement("td"));
    tb.appendChild(tr);
    decorateRow(tr, false);
    if (tr.cells[0]) tr.cells[0].focus();
    changed();
  }

  function decorate(root) {
    $all("table.edit", root).forEach(decorateTable);
    $all(".editblock, span.field", root).forEach(function (el) { el.setAttribute("contenteditable", "true"); });
  }

  // ------------------------------------------------------------ image slots --
  var fileInput = null, slotTarget = null, linkedWarned = false;
  var MAX_INLINE = 1.5 * 1024 * 1024;

  function slotName(slot) {
    var n = slot.getAttribute("data-slot") || "diagram";
    var rep = slot.closest(".report");
    if (rep) {
      var num = rep.querySelector("[data-autonum]");
      n += "_" + ((num && num.textContent) || "R").replace(/[^A-Za-z0-9_-]+/g, "");
    }
    return n;
  }

  function slotPath(slot, ext) { return "diagrams/" + slotName(slot) + "." + ext; }

  function delivBase() { return body.getAttribute("data-deliv-base") || ""; }

  function setSlotState(slot) {
    var img = $("img.slot-img", slot);
    var ins = $("button.slot-insert", slot), rem = $("button.slot-remove", slot), info = $(".slot-info", slot);
    if (ins) ins.textContent = img ? "Replace diagram" : (slot.getAttribute("data-label") || "Insert diagram");
    if (rem) rem.hidden = !img;
    if (info) {
      info.classList.toggle("warn", !!(img && img.hasAttribute("data-linked")));
      info.textContent = !img ? "PNG, SVG or JPG (export from draw.io)" :
        (img.hasAttribute("data-linked") ? "linked file: " + delivBase() + img.getAttribute("data-path") +
          " (too large for browser storage; keep the file there)" :
          "embedded: " + (img.getAttribute("data-file") || "") + " (" + Math.round((img.getAttribute("src") || "").length / 1365) + " kB)");
    }
  }

  function emptyView(slot) {
    return '<div class="slot-empty">' + (slot.getAttribute("data-empty") || "No diagram inserted yet.") + "</div>";
  }

  function pickFile(slot) {
    slotTarget = slot;
    if (!fileInput) {
      fileInput = document.createElement("input");
      fileInput.type = "file";
      fileInput.accept = ".png,.svg,.jpg,.jpeg,image/png,image/svg+xml,image/jpeg";
      fileInput.style.display = "none";
      fileInput.addEventListener("change", function () {
        var f = fileInput.files && fileInput.files[0];
        fileInput.value = "";
        if (f && slotTarget) insertFile(slotTarget, f);
      });
      document.body.appendChild(fileInput);
    }
    fileInput.click();
  }

  function insertFile(slot, f) {
    var ext = (f.name.split(".").pop() || "").toLowerCase();
    if (["png", "svg", "jpg", "jpeg"].indexOf(ext) < 0) { alert("Please choose a PNG, SVG or JPG file."); return; }
    if (f.size > MAX_INLINE && !confirm("This image is " + Math.round(f.size / 1024) + " kB. Browser storage is small (about 5 MB " +
        "for all pages together), so it may be saved as a link to " + delivBase() + slotPath(slot, ext) + " instead of being " +
        "embedded. Export HTML always embeds it. Tip: export from draw.io as SVG or as a smaller PNG.\n\nInsert anyway?")) return;
    var rd = new FileReader();
    rd.onload = function () {
      var view = $(".slot-view", slot);
      view.innerHTML = "";
      var img = document.createElement("img");
      img.className = "slot-img";
      img.alt = slotName(slot);
      img.setAttribute("data-file", f.name);
      img.setAttribute("data-path", slotPath(slot, ext === "jpeg" ? "jpg" : ext));
      img.src = rd.result;
      view.appendChild(img);
      setSlotState(slot);
      changed();
    };
    rd.readAsDataURL(f);
  }

  function removeImage(slot) {
    if (!confirm("Remove this diagram from the page?")) return;
    $(".slot-view", slot).innerHTML = emptyView(slot);
    setSlotState(slot);
    changed();
  }

  function fixLinkedImages(root) {
    $all("img.slot-img[data-linked]", root).forEach(function (img) {
      img.setAttribute("src", delivBase() + img.getAttribute("data-path"));
    });
    $all(".imgslot", root).forEach(setSlotState);
  }

  // ----------------------------------------------------------- save / load --
  function collect(lite) {
    var data = {};
    $all("[data-save]").forEach(function (el) {
      if (!el.id) return;
      var target = (el.tagName === "TABLE") ? el.tBodies[0] : el;
      if (lite && target.querySelector('img.slot-img[src^="data:"]')) {
        var c = target.cloneNode(true);
        $all('img.slot-img[src^="data:"]', c).forEach(function (img) {
          img.setAttribute("data-linked", "1");
          img.setAttribute("src", img.getAttribute("data-path"));
        });
        data[el.id] = c.innerHTML;
      } else {
        data[el.id] = target.innerHTML;
      }
    });
    return data;
  }

  function restore() {
    var raw = null;
    try { raw = localStorage.getItem(storeKey); } catch (e) { return false; }
    if (!raw) return false;
    try {
      var saved = JSON.parse(raw);
      Object.keys(saved.html || {}).forEach(function (id) {
        var el = document.getElementById(id);
        if (!el) return;
        var target = (el.tagName === "TABLE") ? el.tBodies[0] : el;
        target.innerHTML = saved.html[id];
      });
      fixLinkedImages(document);
      setStatus("restored from this browser (" + (saved.time || "?") + ")");
      return true;
    } catch (e) {
      console.error("could not restore saved content", e);
      return false;
    }
  }

  function save() {
    saveTimer = null;
    var time = new Date().toLocaleString();
    try {
      localStorage.setItem(storeKey, JSON.stringify({ time: time, html: collect(false) }));
      setStatus("saved in this browser " + new Date().toLocaleTimeString());
      return;
    } catch (e) { /* most likely over quota because of embedded images: retry with linked images */ }
    try {
      localStorage.setItem(storeKey, JSON.stringify({ time: time, html: collect(true) }));
      var paths = $all('img.slot-img[src^="data:"]').map(function (i) { return delivBase() + i.getAttribute("data-path"); });
      setStatus("saved, but diagrams are too large for browser storage: stored as links - use Export HTML", true);
      if (!linkedWarned && paths.length) {
        linkedWarned = true;
        alert("Browser storage is full, so the inserted diagrams were saved as links only:\n\n  " + paths.join("\n  ") +
              "\n\nCopy the image files to those paths (in your deliverables folder), and use Export HTML: the exported " +
              "file embeds the images and is complete on its own.");
      }
    } catch (e2) {
      setStatus("NOT saved (browser storage unavailable or full) - use Export HTML", true);
    }
  }

  function changed() {
    setStatus("unsaved changes...", true);
    recalc();
    if (saveTimer) clearTimeout(saveTimer);
    saveTimer = setTimeout(save, 600);
  }

  function setStatus(text, dirty) {
    if (!statusEl) return;
    statusEl.textContent = text;
    statusEl.classList.toggle("dirty", !!dirty);
  }

  // ---------------------------------------------------------------- scores --
  function recalc() {
    $all("table.weighted").forEach(function (tbl) {
      var got = 0, max = 0;
      $all("tbody tr", tbl).forEach(function (tr) {
        var w = parseFloat((($("td.weight", tr) || {}).textContent || "").trim());
        var s = parseFloat((($("td.score", tr) || {}).textContent || "").trim());
        if (!isNaN(w)) {
          max += w * 4;
          if (!isNaN(s)) got += w * Math.max(0, Math.min(4, s));
        }
      });
      var out = document.getElementById(tbl.getAttribute("data-total") || "score-total");
      if (out) out.textContent = max ? (Math.round(got / max * 1000) / 10) + " %  (" + got + " / " + max + " points)" : "-";
    });
  }

  // ---------------------------------------------------------------- export --
  function stamp() {
    var d = new Date();
    function p(n) { return (n < 10 ? "0" : "") + n; }
    return d.getFullYear() + p(d.getMonth() + 1) + p(d.getDate()) + "_" + p(d.getHours()) + p(d.getMinutes());
  }

  function download(name, text, mime) {
    var blob = new Blob([text], { type: mime });
    var a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = name;
    document.body.appendChild(a);
    a.click();
    setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 500);
  }

  function inlineCss(clone) {
    var css = "";
    try {
      Array.prototype.forEach.call(document.styleSheets, function (sh) {
        Array.prototype.forEach.call(sh.cssRules || [], function (r) { css += r.cssText + "\n"; });
      });
    } catch (e) { return; }   // some browsers block cssRules for file:// pages
    if (!css) return;
    var st = clone.ownerDocument.createElement("style");
    st.textContent = css;
    clone.querySelector("head").appendChild(st);
  }

  function exportHtml() {
    save();
    var clone = document.documentElement.cloneNode(true);
    $all(".toolbar, button.addrow, #print-page-style", clone).forEach(function (el) { el.remove(); });
    $all("img.slot-img[data-linked]", clone).forEach(function (img) { img.setAttribute("src", img.getAttribute("data-path")); });
    var snap = stamp();
    clone.querySelector("body").setAttribute("data-snapshot", snap);
    inlineCss(clone);
    var html = "<!DOCTYPE html>\n" + clone.outerHTML;
    download((body.getAttribute("data-export-name") || "document") + "_" + snap + ".html", html, "text/html");
  }

  function csvCell(s) {
    s = (s || "").replace(/\s+/g, " ").trim();
    return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
  }

  function exportCsv() {
    var lines = [];
    $all("table.edit").forEach(function (tbl) {
      var title = tbl.getAttribute("data-title") || (tbl.caption ? tbl.caption.textContent : tbl.id);
      lines.push(csvCell("## " + title));
      if (tbl.tHead && tbl.tHead.rows.length) {
        lines.push($all("th:not(.ctl)", tbl.tHead.rows[0]).map(function (c) { return csvCell(c.textContent); }).join(","));
      }
      $all("tbody tr", tbl).forEach(function (tr) {
        lines.push($all("td:not(.ctl), th", tr).map(function (c) {
          var cb = c.querySelector("input[type=checkbox]");
          return csvCell(cb ? (cb.checked ? "yes" : "no") + " " + c.textContent : c.textContent);
        }).join(","));
      });
      lines.push("");
    });
    download((body.getAttribute("data-export-name") || "document") + "_" + stamp() + ".csv", lines.join("\n"), "text/csv");
  }

  function resetPage() {
    if (!confirm("Discard everything saved in this browser for this page and go back to the original template?")) return;
    try { localStorage.removeItem(storeKey); } catch (e) { /* ignore */ }
    window.location.reload();
  }

  function buildToolbar() {
    var bar = $(".toolbar");
    if (!bar) {
      bar = document.createElement("div");
      bar.className = "toolbar";
      var main = $("main.doc");
      var tb = $(".titleblock", main);
      main.insertBefore(bar, tb ? tb.nextSibling : main.firstChild);
    }
    function btn(label, title, fn) {
      var b = document.createElement("button");
      b.type = "button"; b.textContent = label; b.title = title;
      b.addEventListener("click", fn);
      bar.appendChild(b);
    }
    btn("Export HTML", "download a copy of this page with your content", exportHtml);
    btn("Export CSV", "download all editable tables as CSV", exportCsv);
    btn("Export PDF", "print this page or save it as PDF (A4, choose \"Save as PDF\")", function () {
      if (window.sgdmaExportPdf) window.sgdmaExportPdf(); else window.print();
    });
    btn("Reset", "discard the content saved in this browser", resetPage);
    statusEl = document.createElement("span");
    statusEl.className = "status";
    bar.appendChild(statusEl);
  }

  // ------------------------------------------------------------------ init --
  document.addEventListener("DOMContentLoaded", function () {
    body = document.body;
    storeKey = body.getAttribute("data-store-key") || ("sgdma.edit." + location.pathname);
    var snap = body.getAttribute("data-snapshot");
    if (snap) storeKey += ":snapshot:" + snap;

    buildToolbar();
    var restored = restore();
    decorate(document);
    $all(".imgslot").forEach(setSlotState);
    if (!restored) setStatus("autosave on (this browser)");
    recalc();

    document.addEventListener("input", function (ev) {
      if (ev.target.closest && ev.target.closest("[data-save]")) changed();
    });
    document.addEventListener("change", function (ev) {
      var t = ev.target;
      if (t.type === "checkbox") {
        if (t.checked) t.setAttribute("checked", "checked"); else t.removeAttribute("checked");
        changed();
      }
    });
    document.addEventListener("click", function (ev) {
      var del = ev.target.closest && ev.target.closest("button.delrow");
      if (del) {
        var tr = del.closest("tr");
        var txt = tr.textContent.trim();
        if (!txt || confirm("Delete this row?\n\n" + txt.slice(0, 120))) { tr.remove(); changed(); }
        return;
      }
      var si = ev.target.closest && ev.target.closest("button.slot-insert");
      if (si) { pickFile(si.closest(".imgslot")); return; }
      var sr = ev.target.closest && ev.target.closest("button.slot-remove");
      if (sr) { removeImage(sr.closest(".imgslot")); return; }
      var cl = ev.target.closest && ev.target.closest("button[data-clone]");
      if (cl) {
        var tpl = document.getElementById(cl.getAttribute("data-clone"));
        var dst = document.getElementById(cl.getAttribute("data-target"));
        if (tpl && dst) {
          var frag = tpl.content.cloneNode(true);
          var n = dst.querySelectorAll(".report").length + 1;
          $all("[data-autonum]", frag).forEach(function (el) { el.textContent = el.getAttribute("data-autonum") + n; });
          dst.appendChild(frag);
          decorate(dst);
          $all(".imgslot", dst).forEach(setSlotState);
          changed();
        }
      }
    });
  });
})();

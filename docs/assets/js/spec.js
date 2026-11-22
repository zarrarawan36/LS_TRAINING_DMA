/* =============================================================================
   spec.js - page helpers for the SG-DMA training documents (offline)
     - renders Mermaid diagrams (pre.mermaid) with the local mermaid.min.js
     - renders WaveDrom timing / register diagrams (script type="WaveDrom")
     - remembers the README you opened last, so shared pages can link back
   ============================================================================= */
(function () {
  "use strict";

  var HOME_KEY = "sgdma.docs.home";

  function rememberHome() {
    var body = document.body;
    if (!body) return;
    try {
      if (body.getAttribute("data-home") === "self") {
        localStorage.setItem(HOME_KEY, window.location.href);
      }
      var link = document.getElementById("nav-home");
      var saved = localStorage.getItem(HOME_KEY);
      if (link && saved) {
        link.href = saved;
        link.hidden = false;
        var sep = document.getElementById("nav-home-sep");
        if (sep) sep.hidden = false;
      }
    } catch (e) { /* localStorage may be disabled for file:// pages */ }
  }

  function renderMermaid() {
    if (typeof window.mermaid === "undefined") return;
    if (!document.querySelector("pre.mermaid")) return;
    try {
      window.mermaid.initialize({
        startOnLoad: false,
        securityLevel: "loose",
        theme: "base",
        themeVariables: {
          primaryColor: "#e8f1fa",
          primaryBorderColor: "#0068b5",
          primaryTextColor: "#00285a",
          lineColor: "#00285a",
          fontFamily: "Segoe UI, Helvetica Neue, Arial, sans-serif",
          fontSize: "14px"
        },
        flowchart: { htmlLabels: true, curve: "basis", useMaxWidth: true },
        sequence: { useMaxWidth: true, mirrorActors: false },
        state: { useMaxWidth: true }
      });
      window.mermaid.run({ querySelector: "pre.mermaid" });
    } catch (e) {
      console.error("mermaid render failed", e);
    }
  }

  function renderWaveDrom() {
    if (typeof window.WaveDrom === "undefined") return;
    if (!document.querySelector('script[type="WaveDrom"]')) return;
    try {
      window.WaveDrom.ProcessAll();
    } catch (e) {
      console.error("WaveDrom render failed", e);
    }
  }

  // ----------------------------------------------------------- PDF export --
  // Running header / footer of printed pages (A4) built from the title block and the Owner field.
  function metaValue(name) {
    var out = "";
    Array.prototype.forEach.call(document.querySelectorAll("table.meta td"), function (td) {
      var b = td.querySelector("b");
      if (b && b.textContent.replace(":", "").trim() === name) out = td.textContent.replace(b.textContent, "").trim();
    });
    return out;
  }

  function ownerValue() {
    var out = "";
    Array.prototype.forEach.call(document.querySelectorAll("table.form th"), function (th) {
      if (!out && /^owner/i.test(th.textContent.trim())) {
        var td = th.parentNode.querySelector("td");
        if (td) out = td.textContent.trim();
      }
    });
    return out;
  }

  function cssString(s) { return JSON.stringify(String(s || "").replace(/\s+/g, " ").trim()); }

  function updatePrintHeader() {
    var h1 = document.querySelector("main.doc h1");
    var title = h1 ? h1.textContent : document.title;
    var ip = metaValue("IP");
    var left = (ip ? ip + " | " : "") + title;
    var right = ["Owner: " + (ownerValue() || "-"), "Rev " + (metaValue("Revision") || "-"), metaValue("Date") || ""]
      .filter(Boolean).join(" | ");
    var doc = metaValue("Document");
    var css = "@page { @top-left { content: " + cssString(left) + "; font: 8pt Arial, sans-serif; color: #555; }" +
              " @top-right { content: " + cssString(right) + "; font: 8pt Arial, sans-serif; color: #555; }" +
              " @bottom-left { content: " + cssString(doc) + "; font: 8pt Arial, sans-serif; color: #777; }" +
              " @bottom-right { content: \"Page \" counter(page) \" of \" counter(pages); font: 8pt Arial, sans-serif; color: #777; } }";
    var st = document.getElementById("print-page-style");
    if (!st) {
      st = document.createElement("style");
      st.id = "print-page-style";
      st.media = "print";
      document.head.appendChild(st);
    }
    st.textContent = css;
  }

  window.sgdmaExportPdf = function () {
    updatePrintHeader();
    window.print();
  };

  function addPrintBar() {
    var body = document.body;
    if (!body || !body.hasAttribute("data-printbar") || document.querySelector(".printbar")) return;
    var bar = document.createElement("div");
    bar.className = "printbar";
    bar.innerHTML = '<button type="button">Export PDF</button><span>' + (body.getAttribute("data-printbar") ||
      "choose \"Save as PDF\" as printer; A4") + "</span>";
    bar.querySelector("button").addEventListener("click", window.sgdmaExportPdf);
    var main = document.querySelector("main.doc");
    var tb = main && main.querySelector(".titleblock");
    if (main) main.insertBefore(bar, tb ? tb.nextSibling : main.firstChild);
  }

  document.addEventListener("DOMContentLoaded", function () {
    rememberHome();
    renderWaveDrom();
    renderMermaid();
    addPrintBar();
    updatePrintHeader();
    window.addEventListener("beforeprint", updatePrintHeader);
  });
})();

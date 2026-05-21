---
hide:
  - navigation
  - toc
---

# SCC Lookup

Search for any Draw Steel content by name, type, or SCC code.

<div id="scc-lookup">
  <input type="text" id="scc-search" placeholder="Search by name, type, or SCC code..." autocomplete="off" />
  <div id="scc-results"></div>
  <div id="scc-status"></div>
</div>

<style>
#scc-lookup {
  max-width: 720px;
  margin: 1rem 0;
}

#scc-search {
  width: 100%;
  padding: 0.75rem 1rem;
  font-size: 1rem;
  border: 2px solid var(--md-default-fg-color--lighter);
  border-radius: 6px;
  background: var(--md-default-bg-color);
  color: var(--md-default-fg-color);
  outline: none;
  transition: border-color 0.2s;
  box-sizing: border-box;
}

#scc-search:focus {
  border-color: var(--md-accent-fg-color);
}

#scc-results {
  margin-top: 0.5rem;
  max-height: 60vh;
  overflow-y: auto;
}

#scc-status {
  margin-top: 0.5rem;
  font-size: 0.85rem;
  color: var(--md-default-fg-color--light);
}

.scc-entry {
  display: block;
  padding: 0.6rem 0.75rem;
  border-bottom: 1px solid var(--md-default-fg-color--lightest);
  text-decoration: none;
  color: var(--md-default-fg-color);
  transition: background 0.15s;
}

.scc-entry:hover, .scc-entry.scc-active {
  background: var(--md-code-bg-color);
  text-decoration: none;
}

.scc-entry-name {
  font-weight: 600;
  font-size: 1rem;
}

.scc-entry-type {
  display: inline-block;
  margin-left: 0.5rem;
  padding: 0.1rem 0.4rem;
  font-size: 0.75rem;
  border-radius: 3px;
  background: var(--md-accent-fg-color);
  color: var(--md-accent-bg-color);
  vertical-align: middle;
}

.scc-entry-code {
  display: block;
  font-size: 0.8rem;
  color: var(--md-default-fg-color--light);
  font-family: var(--md-code-font-family);
  margin-top: 0.15rem;
}

.scc-highlight {
  background: var(--md-accent-fg-color--transparent);
  border-radius: 2px;
}
</style>

<script>
(function() {
  var entries = null;
  var searchEl, resultsEl, statusEl;
  var activeIndex = -1;
  var visibleEntries = [];
  var MAX_RESULTS = 50;

  function init() {
    searchEl = document.getElementById("scc-search");
    resultsEl = document.getElementById("scc-results");
    statusEl = document.getElementById("scc-status");
    if (!searchEl) return;

    statusEl.textContent = "Loading SCC registry...";

    fetch(window.location.pathname.replace(/\/api\/?$/, "") + "/api/v1/scc.json")
      .then(function(r) { return r.json(); })
      .then(function(data) {
        entries = data.entries;
        statusEl.textContent = entries.length + " entries loaded. Start typing to search.";
        searchEl.addEventListener("input", onInput);
        searchEl.addEventListener("keydown", onKeydown);
      })
      .catch(function() {
        statusEl.textContent = "Failed to load SCC registry.";
      });
  }

  function onInput() {
    var query = searchEl.value.trim().toLowerCase();
    activeIndex = -1;

    if (query.length < 2) {
      resultsEl.innerHTML = "";
      statusEl.textContent = entries.length + " entries loaded. Start typing to search.";
      visibleEntries = [];
      return;
    }

    var terms = query.split(/\s+/);
    var matches = [];

    for (var i = 0; i < entries.length; i++) {
      var e = entries[i];
      var haystack = (e.name + " " + e.type + " " + e.scc).toLowerCase();
      var allMatch = true;
      for (var t = 0; t < terms.length; t++) {
        if (haystack.indexOf(terms[t]) === -1) {
          allMatch = false;
          break;
        }
      }
      if (allMatch) {
        matches.push(e);
        if (matches.length >= MAX_RESULTS) break;
      }
    }

    visibleEntries = matches;
    renderResults(matches, terms, entries.length);
  }

  function renderResults(matches, terms, total) {
    if (matches.length === 0) {
      resultsEl.innerHTML = "";
      statusEl.textContent = "No results found.";
      return;
    }

    var html = [];
    for (var i = 0; i < matches.length; i++) {
      var e = matches[i];
      html.push(
        '<a class="scc-entry" href="' + e.url + '" data-idx="' + i + '">' +
          '<span class="scc-entry-name">' + highlight(e.name, terms) + '</span>' +
          '<span class="scc-entry-type">' + escapeHtml(e.type) + '</span>' +
          '<span class="scc-entry-code">' + highlight(e.scc, terms) + '</span>' +
        '</a>'
      );
    }
    resultsEl.innerHTML = html.join("");

    var countText = matches.length >= MAX_RESULTS
      ? MAX_RESULTS + "+ results (showing first " + MAX_RESULTS + ")"
      : matches.length + (matches.length === 1 ? " result" : " results");
    statusEl.textContent = countText;
  }

  function onKeydown(e) {
    if (visibleEntries.length === 0) return;

    if (e.key === "ArrowDown") {
      e.preventDefault();
      activeIndex = Math.min(activeIndex + 1, visibleEntries.length - 1);
      updateActive();
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      activeIndex = Math.max(activeIndex - 1, -1);
      updateActive();
    } else if (e.key === "Enter" && activeIndex >= 0) {
      e.preventDefault();
      var link = resultsEl.querySelector('.scc-entry[data-idx="' + activeIndex + '"]');
      if (link) window.location.href = link.href;
    }
  }

  function updateActive() {
    var all = resultsEl.querySelectorAll(".scc-entry");
    for (var i = 0; i < all.length; i++) {
      all[i].classList.toggle("scc-active", i === activeIndex);
    }
    if (activeIndex >= 0 && all[activeIndex]) {
      all[activeIndex].scrollIntoView({ block: "nearest" });
    }
  }

  function highlight(text, terms) {
    var safe = escapeHtml(text);
    for (var i = 0; i < terms.length; i++) {
      if (!terms[i]) continue;
      var escaped = escapeRegex(terms[i]);
      safe = safe.replace(new RegExp("(" + escaped + ")", "gi"), '<span class="scc-highlight">$1</span>');
    }
    return safe;
  }

  function escapeHtml(s) {
    var d = document.createElement("div");
    d.appendChild(document.createTextNode(s));
    return d.innerHTML;
  }

  function escapeRegex(s) {
    return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
</script>

---

## API Documentation

The SCC Resolution API is a static JSON API that resolves [Steel Compendium Classification (SCC)](../api/v1/index.json) codes to website URLs and metadata.

### Endpoints

All endpoints are relative to `https://steelcompendium.io/api/v1/`.

| Endpoint | Description |
|----------|-------------|
| [`index.json`](v1/index.json) | API metadata and discovery |
| [`scc.json`](v1/scc.json) | Full registry -- all entries and aliases |
| [`types.json`](v1/types.json) | Entries grouped by content type |
| `resolve/{source}/{type}/{item}.json` | Single entry lookup |

### Single Entry Lookup

Resolve an SCC code to its website URL and metadata:

```
GET /api/v1/resolve/mcdm.heroes.v1/class/fury.json
```

```json
{
  "scc": "mcdm.heroes.v1/class/fury",
  "url": "https://steelcompendium.io/v2/Browse/class/fury/",
  "name": "Fury",
  "type": "class",
  "source": "mcdm.heroes.v1"
}
```

### Bulk Registry

Download the full registry for offline use or indexing:

```
GET /api/v1/scc.json
```

Returns all entries sorted by SCC code, plus alias mappings.

### Usage Example

```javascript
// Resolve a single SCC code
fetch("https://steelcompendium.io/api/v1/resolve/mcdm.heroes.v1/class/fury.json")
  .then(r => r.json())
  .then(entry => window.open(entry.url));
```

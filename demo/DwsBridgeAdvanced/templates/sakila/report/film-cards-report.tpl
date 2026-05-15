<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title><% reportTitle %></title>
<style>
:root {
  --bg: #f3efe7;
  --panel: #fffaf3;
  --ink: #1d1a16;
  --muted: #5f564d;
  --line: #e5d6c5;
  --accent: #c96f2d;
  --shadow: rgba(0, 0, 0, 0.08);
}
body {
  margin: 0;
  background: radial-gradient(circle at top, #fff8ef 0%, var(--bg) 58%, #eadcc9 100%);
  color: var(--ink);
  font: 16px/1.5 "Segoe UI", Arial, sans-serif;
}
.page {
  max-width: 1240px;
  margin: 0 auto;
  padding: 32px 24px 48px;
}
.hero,
.panel,
.film-card {
  background: rgba(255, 250, 243, 0.94);
  border: 1px solid var(--line);
  box-shadow: 0 18px 48px var(--shadow);
}
.hero,
.panel {
  border-radius: 24px;
}
.hero {
  padding: 28px 30px;
}
.eyebrow {
  margin: 0 0 10px;
  color: var(--accent);
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}
.hero h1,
.panel h2,
.film-copy h3 {
  font-family: Georgia, "Times New Roman", serif;
}
.hero h1 {
  margin: 0 0 12px;
  font-size: 42px;
  line-height: 1.05;
}
.hero-copy {
  margin: 0;
  max-width: 800px;
  font-size: 18px;
  color: var(--muted);
}
.hero-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 18px;
}
.hero-meta span {
  padding: 8px 12px;
  border-radius: 999px;
  border: 1px solid var(--line);
  background: #fff;
  color: var(--muted);
  font-size: 13px;
}
.panel {
  margin-top: 22px;
  padding: 22px 24px;
}
.panel h2 {
  margin: 0 0 12px;
  font-size: 26px;
}
.panel p {
  margin: 0;
  color: var(--muted);
}
.film-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 18px;
  margin-top: 18px;
}
.film-card {
  overflow: hidden;
  border-radius: 22px;
  display: flex;
  flex-direction: column;
}
.film-card img {
  display: block;
  width: 100%;
  aspect-ratio: 2 / 3;
  object-fit: cover;
  background: #e9dfd4;
}
.film-copy {
  padding: 18px 20px 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.film-copy h3 {
  margin: 0;
  font-size: 24px;
}
.description {
  margin: 0;
  color: #453c33;
}
.film-meta {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px 14px;
  margin: 0;
}
.film-meta div {
  border-radius: 12px;
  background: #f8f4ec;
  padding: 10px 12px;
}
.film-meta dt {
  margin: 0;
  font-size: 12px;
  color: #7b6f63;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}
.film-meta dd {
  margin: 4px 0 0;
  font-weight: 600;
}
.cast {
  margin: 0;
  color: #574d44;
}
.footer {
  margin-top: 22px;
  padding: 16px 18px;
  border-radius: 18px;
  background: #1f2933;
  color: #f8fafc;
}
.footer strong {
  color: #f4c987;
}
@media (max-width: 720px) {
  .page {
    padding: 22px 16px 40px;
  }
  .hero h1 {
    font-size: 32px;
  }
  .film-meta {
    grid-template-columns: 1fr;
  }
}
</style>
</head>
<body>
<div class="page">
  <section class="hero">
    <p class="eyebrow">Generated From <% databaseName %></p>
    <h1><% reportTitle %></h1>
    <p class="hero-copy">This Sakila report stays on a single HTML page and renders film cards from data loaded through DWScript scripts. Each card is sourced from <b><% databaseName %></b> and includes poster artwork cached on demand.</p>
    <div class="hero-meta">
      <span>Film cards <% filmCountText %></span>
      <span>Bridge showcase <% scenarioCountText %> scenarios</span>
      <span>Stage <% reportStage %></span>
      <span>Generated <% generatedAt %></span>
    </div>
  </section>

  <section class="panel">
    <h2>Film Cards</h2>
    <p>Each card below is populated from `sakila.db` through `film_catalog.dws`. The report remains one page while still showing rich per-film metadata.</p>
    <div class="film-grid">
      <% for film of films %>
      <article class="film-card">
        <img src="<% film.poster_path %>" alt="<% film.title %> poster" />
        <div class="film-copy">
          <p class="eyebrow"><% film.category_name %></p>
          <h3><% film.title %></h3>
          <p class="description"><% film.description_text %></p>
          <dl class="film-meta">
            <div><dt>Release</dt><dd><% film.release_year %></dd></div>
            <div><dt>Rating</dt><dd><% film.rating %></dd></div>
            <div><dt>Length</dt><dd><% film.length %> min</dd></div>
            <div><dt>Rentals</dt><dd><% film.rental_count %></dd></div>
            <div><dt>Rental Rate</dt><dd><% film.rental_rate_text %></dd></div>
            <div><dt>Replacement</dt><dd><% film.replacement_cost_text %></dd></div>
            <div><dt>Rental Days</dt><dd><% film.rental_duration %></dd></div>
            <div><dt>Category</dt><dd><% film.category_name %></dd></div>
          </dl>
          <p class="cast"><strong>Cast:</strong> <% film.actor_names %></p>
        </div>
      </article>
      <% end %>
    </div>
  </section>

  <footer class="footer">
    <strong>Diagnostics</strong>: <% diagnosticsSummary %><br>
    <strong>Generated At</strong>: <% generatedAt %>
  </footer>
</div>
</body>
</html>

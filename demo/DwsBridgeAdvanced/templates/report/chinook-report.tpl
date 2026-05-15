<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title><% reportTitle %></title>
<style>
:root {
  --bg: #f5efe6;
  --panel: #fffaf3;
  --ink: #1f2933;
  --muted: #52606d;
  --line: #d9c9b7;
  --accent: #0f766e;
  --accent-soft: #d8f3ef;
  --warm: #c96f2d;
  --shadow: rgba(42, 56, 66, 0.08);
}
body {
  margin: 0;
  font-family: "Segoe UI", Tahoma, sans-serif;
  color: var(--ink);
  background: radial-gradient(circle at top, #fff8ef 0%, var(--bg) 58%, #eadcc9 100%);
}
.page {
  max-width: 1180px;
  margin: 0 auto;
  padding: 40px 28px 56px;
}
.hero,
.panel,
.scenario-card,
.kpi {
  background: rgba(255, 250, 243, 0.94);
  border: 1px solid var(--line);
  box-shadow: 0 20px 48px var(--shadow);
}
.hero,
.panel {
  border-radius: 24px;
}
.hero {
  padding: 28px 30px;
  margin-bottom: 24px;
}
.eyebrow {
  margin: 0 0 10px;
  color: var(--warm);
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}
.hero h1 {
  margin: 0 0 12px;
  font-size: 42px;
  line-height: 1.05;
}
.hero-copy {
  margin: 0 0 18px;
  max-width: 780px;
  font-size: 18px;
  line-height: 1.6;
  color: var(--muted);
}
.hero-banner {
  display: inline-block;
  padding: 10px 14px;
  border-radius: 999px;
  background: var(--accent-soft);
  color: var(--accent);
  font-weight: 700;
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
  font-size: 13px;
  color: var(--muted);
}
.grid {
  display: grid;
  gap: 18px;
}
.kpis {
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  margin-bottom: 24px;
}
.kpi {
  padding: 18px 20px;
  border-radius: 20px;
}
.kpi strong {
  display: block;
  font-size: 32px;
  line-height: 1;
  margin-bottom: 8px;
}
.kpi span {
  color: var(--muted);
  font-size: 14px;
}
.two-up {
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  margin-bottom: 24px;
}
.panel {
  padding: 22px 24px;
}
.panel h2,
.showcase h2 {
  margin: 0 0 14px;
  font-size: 24px;
}
.panel p {
  margin: 0 0 12px;
  line-height: 1.6;
}
.callout {
  margin: 0 0 14px;
  padding: 14px 16px;
  border-left: 4px solid var(--accent);
  background: #fff;
  border-radius: 14px;
}
.note {
  color: var(--muted);
}
.score {
  font-size: 28px;
  font-weight: 700;
  color: var(--accent);
}
.table-wrap {
  overflow-x: auto;
}
table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}
th,
td {
  padding: 10px 12px;
  border-bottom: 1px solid var(--line);
  text-align: left;
}
th {
  color: var(--muted);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}
.artist-blurb {
  margin-top: 0;
  padding: 18px 20px;
  border-radius: 18px;
  background: linear-gradient(135deg, #fff 0%, #fff3e7 100%);
  border: 1px solid var(--line);
}
.showcase {
  margin-top: 24px;
}
.showcase-head {
  margin-bottom: 14px;
}
.showcase-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 18px;
}
.scenario-card {
  border-radius: 22px;
  padding: 18px 20px;
}
.scenario-card h3 {
  margin: 0 0 8px;
  font-size: 18px;
}
.scenario-card p {
  margin: 0 0 12px;
  color: var(--muted);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}
.scenario-card pre {
  margin: 0;
  padding: 14px 16px;
  border-radius: 16px;
  background: #1f2933;
  color: #f8fafc;
  overflow-x: auto;
  white-space: pre-wrap;
  word-break: break-word;
  font-family: Consolas, "Courier New", monospace;
  font-size: 13px;
  line-height: 1.55;
}
.album-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 18px;
  margin-top: 16px;
}
.album-card {
  overflow: hidden;
  border-radius: 22px;
  background: rgba(255, 250, 243, 0.94);
  border: 1px solid var(--line);
  box-shadow: 0 20px 48px var(--shadow);
}
.album-card img {
  display: block;
  width: 100%;
  aspect-ratio: 2 / 3;
  object-fit: cover;
  background: #e8dfd3;
}
.album-card-copy {
  padding: 18px 20px 20px;
}
.album-card-copy h3 {
  margin: 0 0 8px;
  font-size: 20px;
}
.album-card-copy p {
  margin: 0 0 10px;
}
.album-card-copy a {
  color: var(--accent);
  text-decoration: none;
}
.footer {
  margin-top: 24px;
  padding: 16px 18px;
  border-radius: 18px;
  background: #1f2933;
  color: #f8fafc;
}
.footer strong {
  color: #f4c987;
}
@media (max-width: 640px) {
  .page {
    padding: 22px 16px 40px;
  }
  .hero h1 {
    font-size: 32px;
  }
}
</style>
</head>
<body>
<div class="page">
  <section class="hero">
    <p class="eyebrow">Generated from <% databaseName %></p>
    <h1><% reportTitle %></h1>
    <p class="hero-copy"><% artistSummaryText %></p>
    <div class="hero-banner"><% bannerText %></div>
    <div class="hero-meta">
      <span>Run by <% currentUser %></span>
      <span>Generated <% generatedAt %></span>
      <span>Stage flow <% publicationFlowText %></span>
      <span>Final stage <% reportStage %></span>
      <span>Bridge showcase <% scenarioCountText %> scenarios</span>
    </div>
  </section>

  <section class="grid kpis">
    <article class="kpi"><strong><% totals.artistsText %></strong><span>Artists</span></article>
    <article class="kpi"><strong><% totals.albumsText %></strong><span>Albums</span></article>
    <article class="kpi"><strong><% totals.tracksText %></strong><span>Tracks</span></article>
    <article class="kpi"><strong><% totals.customersText %></strong><span>Customers</span></article>
    <article class="kpi"><strong><% totals.invoicesText %></strong><span>Invoices</span></article>
    <article class="kpi"><strong><% totals.playlistsText %></strong><span>Playlists</span></article>
  </section>

  <section class="grid two-up">
    <article class="panel">
      <h2>Executive Summary</h2>
      <p class="callout"><% playlistSummaryText %></p>
      <p class="callout"><% supportSummaryText %></p>
      <p class="score"><% scoreSummaryText %></p>
      <p class="note">The summary above is assembled from the same DWS showcase run that powers the scenario gallery below.</p>
    </article>
    <article class="panel">
      <h2>Customer Spotlight</h2>
      <p class="callout"><strong><% customer.fullName %></strong> from <% customer.country %> spent <% customer.revenueText %>.</p>
      <p class="note">Top US customer by revenue in the Chinook sample.</p>
    </article>
  </section>

  <section class="panel" style="margin-bottom: 24px;">
    <h2>Artist Spotlight</h2>
    <div class="artist-blurb">
      <h3><% artist.name %></h3>
      <p>Tracks: <% artist.trackCountText %></p>
      <p class="note"><% artistSummaryText %></p>
    </div>
  </section>

  <section class="grid two-up">
    <article class="panel">
      <h2>Top Artists</h2>
      <div class="table-wrap">
        <table>
          <thead>
            <tr><th>Artist</th><th>Tracks</th></tr>
          </thead>
          <tbody>
            <% for artistItem of topArtists %>
            <tr><td><% artistItem.name %></td><td><% artistItem.trackCountText %></td></tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </article>
    <article class="panel">
      <h2>Top Chinook Genres</h2>
      <p class="note"><% genreSummaryText %></p>
      <div class="table-wrap">
        <table>
          <thead>
            <tr><th>Genre</th><th>Tracks</th></tr>
          </thead>
          <tbody>
            <% for item of genres %>
            <tr><td><% item.name %></td><td><% item.trackCountText %></td></tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </article>
  </section>

  <section class="grid two-up" style="margin-top: 24px;">
    <article class="panel">
      <h2>Top Customers</h2>
      <div class="table-wrap">
        <table>
          <thead>
            <tr><th>Customer</th><th>Country</th><th>Revenue</th><th>Invoices</th></tr>
          </thead>
          <tbody>
            <% for customerItem of topCustomers %>
            <tr>
              <td><% customerItem.fullName %></td>
              <td><% customerItem.country %></td>
              <td><% customerItem.revenueText %></td>
              <td><% customerItem.invoiceCountText %></td>
            </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </article>
    <article class="panel">
      <h2>Sales by Country</h2>
      <div class="table-wrap">
        <table>
          <thead>
            <tr><th>Country</th><th>Revenue</th><th>Invoices</th></tr>
          </thead>
          <tbody>
            <% for countryItem of countrySales %>
            <tr>
              <td><% countryItem.country %></td>
              <td><% countryItem.revenueText %></td>
              <td><% countryItem.invoiceCountText %></td>
            </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </article>
  </section>

  <section class="panel" style="margin-top: 24px;">
    <h2>Album Pages</h2>
    <p class="note">Generated <% albumPageCountText %> linked album pages with poster-cache artwork produced through the DWScript poster helper.</p>
    <div class="album-grid">
      <% for pageItem of albumPages %>
      <article class="album-card">
        <img src="<% pageItem.posterPath %>" alt="<% pageItem.title %> poster" />
        <div class="album-card-copy">
          <p class="eyebrow"><% pageItem.artistName %></p>
          <h3><a href="<% pageItem.pageHref %>"><% pageItem.title %></a></h3>
          <p><% pageItem.summaryText %></p>
          <p class="note">Genre <% pageItem.genreName %> &middot; Tracks <% pageItem.trackCountText %> &middot; Revenue <% pageItem.revenueText %></p>
        </div>
      </article>
      <% end %>
    </div>
  </section>

  <section class="showcase">
    <div class="showcase-head">
      <h2>DWScript Integration Showcase</h2>
      <p class="note">Each card below is produced by the same CLI run and captures one integration path used by the engine against the Chinook dataset.</p>
    </div>
    <div class="showcase-grid">
      <% for scenarioItem of scenarioResults %>
      <article class="scenario-card">
        <p>Bridge Scenario</p>
        <h3><% scenarioItem.name %></h3>
        <pre><% scenarioItem.output %></pre>
      </article>
      <% end %>
    </div>
  </section>

  <footer class="footer">
    <strong>Diagnostics</strong>: <% diagnosticsSummary %>
  </footer>
</div>
</body>
</html>

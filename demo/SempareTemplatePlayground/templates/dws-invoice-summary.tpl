<div class="bridge-demo">
  <h2>SQLite-backed invoice summary via Dws()</h2>
  <% summary := Dws('invoice_summary', { "Invoice": Invoice }) %>
  <p><strong>Invoice:</strong> <% summary.invoiceNo %></p>
  <p><strong>Client:</strong> <% summary.client %></p>
  <p><strong>Status:</strong> <% summary.status %></p>
  <p><strong>Work total:</strong> <% summary.workTotal %> <% summary.currency %></p>
  <p><strong>Total:</strong> <% summary.total %> <% summary.currency %></p>
</div>

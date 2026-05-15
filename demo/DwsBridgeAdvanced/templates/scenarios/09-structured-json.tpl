Structured JSON-like result via DwsCall
<% report := DwsCall('genre_json', 'Build', _) %>
<% report.title %>
<% for item of report.items %><% item.name %> (<% item.tracks %>)<% betweenitems %>, <% end %>

Inline value helper
Composite Chinook score: <% DwsInline('function Main(data : JSONVariant) : Integer; begin Result := data.artistCount + data.customerCount + data.playlistCount; end;', 'Main', { "artistCount": totals.artists, "customerCount": totals.customers, "playlistCount": totals.playlists }) %>

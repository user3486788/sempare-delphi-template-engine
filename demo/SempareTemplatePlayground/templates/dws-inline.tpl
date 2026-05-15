<div class="bridge-demo">
  <h2>Inline helper</h2>
  <p><% DwsInline('function Main(data : JSONVariant) : String; begin Result := String(data.user) + String(data.stage); end;', 'Main', { "user": currentUser, "stage": stage }) %></p>
</div>

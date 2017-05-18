class simpsetup::togen {

$togen_template = @(END)
<% $simpsetup::servers.each |$number| { %>
server<%= $number %>.<%= $simpsetup::domain %>
<% } %>
<% $simpsetup::clients.each |$number| { %>
ws<%= $number %>.<%= $simpsetup::domain %>
<% } %>
END

  file {  '/var/simp/environments/simp/FakeCA/togen':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content =>  inline_epp($togen_template)
  }

  exec { 'generate certs from togen':
    command => '/var/simp/environments/simp/FakeCA/gencerts_nopash.sh',
    cwd     => '/var/simp/environments/simp/FakeCA'
    require => File['/var/simp/environments/simp/FakeCA/togen']
  }
}

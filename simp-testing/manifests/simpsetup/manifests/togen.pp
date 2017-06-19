#  This takes the server and client list from the simpsetup
#  and generates certicates for them.
#  It use the domain name from simpsetup also.
#  It users server## and ws## for the names of the systems.
#
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
    content =>  epp('simpsetup/togen.epp')
  }

  exec { 'generate certs from togen':
    command => '/var/simp/environments/simp/FakeCA/gencerts_nopass.sh',
    cwd     => '/var/simp/environments/simp/FakeCA',
    creates => "/var/simp/environments/simp/site_files/pki_files/files/keydist/ws33.${simpsetup::domain}"
    require => File['/var/simp/environments/simp/FakeCA/togen']
  }
}

#  This takes the server and client list from the simpsetup
#  and generates certicates for them.
#  It use the domain name from simpsetup also.
#  It users server## and ws## for the names of the systems.
#
class simpsetup::togen (
  String $env = $simpsetup::environment
){

$togen_template = @(END)
<% $simpsetup::servers.each |$number| { %>
server<%= $number %>.<%= $simpsetup::domain %>
<% } %>
<% $simpsetup::clients.each |$number| { %>
ws<%= $number %>.<%= $simpsetup::domain %>
<% } %>
END

  file {  "/var/simp/environments/${env}/FakeCA/togen":
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content =>  epp('simpsetup/togen.epp')
  }

  exec { 'generate certs from togen':
    command => "/var/simp/environments/${env}/FakeCA/gencerts_nopass.sh",
    cwd     => "/var/simp/environments/${env}/FakeCA",
    creates => "/var/simp/environments/${env}/site_files/pki_files/files/keydist/ws33.${simpsetup::domain}",
    require => File["/var/simp/environments/${env}/FakeCA/togen"]
  }
}

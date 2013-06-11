package Dancer::Plugin::Auth::RBAC::Credentials::LDAP;
use Catmandu::Sane;
use Catmandu;
use Catmandu::Util qw(:is);
use Net::LDAP;
use Net::LDAPS;
use Data::Dumper;

my $opts = {
  host => 'ldaps.ugent.be', 
  secure => 1,
  applications_base => "ugentID=870910100341,ou=applications,dc=ugent,dc=be",
  applications_password => "{b1bb1b}",
  auth_base => "ugentID=%s,ou=people,dc=UGent,dc=be",
  auth_attr => "personNumber",
  search_filter => "(uid=%s)",
  search_base => "ou=people,dc=ugent,dc=be",
  search_scope => "one",
  search_attrs => [qw(ugentID uid ugentpreferredsn ugentpreferredgivenname mail departmentnumber objectclass)],
  args_to_new => {
    timeout => 3,
    port => 636
  }
};

my $ldap;
if($opts->{secure}){
  $ldap = Net::LDAPS->new($opts->{host},%{ $opts->{args_to_new} });
}else{
  $ldap = Net::LDAP->new($opts->{host},%{ $opts->{args_to_new} });
}
if(!$ldap){
  die("unable to connect ldap host '".$opts->{host}."'");
}
if($opts->{applications_base}){
  my $bind = $ldap->bind($opts->{applications_base},password => $opts->{applications_password});
  if($bind->code != Net::LDAP::LDAP_SUCCESS){
    die("ldap: bind to " . $opts->{applications_base} .  " failed");
  }
}

my $username = "njfranck";
my %args = ();
$args{filter} = sprintf($opts->{search_filter}, $username);
$args{base}   = $opts->{search_base};
$args{scope}  = $opts->{search_scope} if $opts->{search_scope};
$args{attrs}  = $opts->{search_attrs} if $opts->{search_attrs};

print STDERR Dumper(\%args);

my $query = $ldap->search(%args);

print Dumper($query->as_struct);



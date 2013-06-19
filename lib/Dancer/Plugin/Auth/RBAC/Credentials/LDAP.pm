package Dancer::Plugin::Auth::RBAC::Credentials::LDAP;
use Catmandu::Sane;
use Catmandu;
use Catmandu::Util qw(:is);
use base qw/Dancer::Plugin::Auth::RBAC::Credentials/;
use Dancer qw(:syntax);
use Net::LDAP;
use Net::LDAPS;

sub opts {
  my($self,$c) = @_;
  state $opts = config->{plugins}->{'Auth::RBAC'}->{'credentials'}->{options};
}
sub authorize {
  my($self,$opts,@arguments) = @_;

  #what are you doing here? You're already in!
  my $user = $self->credentials;
  if($user && ($user->{id} || $user->{login}) && !@{$user->{error}}){
    return $user;
  }

  #just checking?
  return unless scalar(@arguments) >= 2;

  my($username,$password) = @arguments;

  #not in white list?
  if(is_array_ref($opts->{whitelist})){
    return undef unless (grep {/$username/} @{$opts->{whitelist}});
  }

  my $account = $self->verify($username,$password);
    
  return if(!is_hash_ref($account));

  my $session_data = {
    id    => $account->{ $opts->{id_attr} }->[0],
    name  => $account->{ $opts->{name_attr} }->[0],
    login => $account->{ $opts->{login_attr} }->[0],
    roles => $account->{ $opts->{roles_attr} },
    error => []
  };

  return $self->credentials($session_data);

}
sub ldap {
  my($self) = @_;
  state $ldap = do {    
    my $opts = $self->opts();
    my $l;
    if($opts->{secure}){
      $l = Net::LDAPS->new($opts->{host},%{ $opts->{args_to_new} });
    }else{
      $l = Net::LDAP->new($opts->{host},%{ $opts->{args_to_new} });
    }
    if(!$l){
      die("unable to connect ldap host '".$opts->{host}."'");
    }
    if($opts->{applications_base}){
      my $bind = $l->bind($opts->{applications_base},password => $opts->{applications_password});
      if($bind->code != Net::LDAP::LDAP_SUCCESS){
        die("ldap: bind to " . $opts->{applications_base} .  " failed");
      }
    }
    $l;
  };
}

sub verify {
  my($self,$username,$password)=@_;

  my $opts = $self->opts();

  #haal info over
  my $entry = $self->lookup($username);
  if(!$entry){
    return undef;
  }

  #kan je hier verbinding op halen
  my $base;
  if($opts->{auth_attr}){
    $base = sprintf($opts->{auth_base},$entry->{ $opts->{auth_attr} }->[0]);
  }else{
    $base = sprintf($opts->{auth_base},$username);
  }
  my $bind = $self->ldap()->bind($base,password => $password);
  if($bind->code != Net::LDAP::LDAP_SUCCESS){
    return undef;
  }

  return $entry;

}
sub lookup {
  my($self,$username) = @_;

  my $opts = $self->opts;

  my %args = ();
  $args{filter} = sprintf($opts->{search_filter}, $username);
  $args{base}   = $opts->{search_base};
  $args{scope}  = $opts->{search_scope} if $opts->{search_scope};
  $args{attrs}  = $opts->{search_attrs} if $opts->{search_attrs};

  my $query = $self->ldap()->search(%args);

  if ($query->code != Net::LDAP::LDAP_SUCCESS or $query->count != 1) {
    return;
  }
  my $struct = $query->as_struct;
  my($entry) = values(%$struct);
  $entry;
}


1;

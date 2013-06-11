package Circulation::App::Login;
our $VERSION = '1.0';
use Catmandu::Sane;
use Catmandu;
use Dancer qw(:syntax);
use Dancer::Plugin::Auth::RBAC;
use Catmandu::Util qw(:is);
use URI::Escape qw(uri_escape uri_unescape);

set layout => undef;

post('/login',sub{
  return redirect( uri_for(config->{default_route} || "/") ) if authd;
  my $params = params;
  my $auth = auth($params->{username},$params->{password});
  if($auth->errors){
    forward('/login',{ errors => $auth->errors },{ method => 'GET' });
  }else{
    my $service = is_string($params->{service})? uri_unescape($params->{service}) : uri_for(config->{default_route} || "/");
    return redirect( $service );
  }
});
get('/login',sub{
  return redirect( uri_for(config->{default_route} || "/") ) if authd;
  template('login',{ errors => params->{errors} || [], auth => auth() });
});
get('/logout',sub{
  if(authd){
    auth->revoke();
  }
  redirect( uri_for("/login") );
});

1;

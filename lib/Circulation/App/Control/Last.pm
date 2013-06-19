package Circulation::App::Control::Last;
use Dancer ':syntax';
use Catmandu::Sane;
use Dancer::Plugin::Auth::RBAC;

prefix undef;

hook before_template_render => sub {
  my $tokens = $_[0];
  $tokens->{auth} = auth();
  $tokens->{authd} = authd(); 
  $tokens->{uri_for_search} = \&uri_for_search;
};

any('/not_found',sub{
  status 'not_found';
  header( "refresh" => config->{refresh_rate}."; URL=".uri_for(config->{default_app}) );
  template('not_found',{
    requested_path => uri_for(params->{requested_path})
  });
});
any qr{.*} => sub {
  status 'not_found';
  header( "refresh" => config->{refresh_rate}."; URL=".uri_for(config->{default_app}) );
  template('not_found',{
    requested_path => uri_for(request->path)
  });
};

sub uri_for_search {
  my($path,$more) = @_;
  my $params = params();
  if($more){
    $params = {%$params};
    for my $key (keys %$more) {
      my $val = $more->{$key};
      if (!defined($val) || (!ref($val) && !length($val))) {
        delete $params->{$key};
      } else {
        $params->{$key} = $val;
      }
    }
  }
  return request->uri_for($path,$params);
}

true;

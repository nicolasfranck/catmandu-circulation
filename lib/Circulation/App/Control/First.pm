package Circulation::App::Control::First;
use Dancer ':syntax';
use Catmandu::Sane;
use Dancer::Plugin::Auth::RBAC;
use URI::Escape qw(uri_escape);
use List::MoreUtils qw(first_index);

hook before => sub {

  state $private_routes = config->{private_routes} || [];
  my $path = request->path;
  
  my $index = first_index { $path eq $_; } @$private_routes;

  if($index >= 0 && !authd){

    my $service = uri_escape(uri_for(request->path));
    return redirect(uri_for("/login")."?service=$service");
    
  }
};

true;

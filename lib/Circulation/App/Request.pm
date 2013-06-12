package Circulation::App::Request;
our $VERSION = '1.0';
use Catmandu::Sane;
use Catmandu;
use Dancer qw(:syntax);
use Dancer::Plugin::Lexicon;
use Dancer::Plugin::Stomp;
use Circulation qw(:all);
use Circulation::Parser::Request;
use Circulation::Indexable::Request;
use Catmandu::Util qw(:is :array require_package);
use Try::Tiny;

#list records, and filter them by query
prefix '/request' => sub {

  get '/' => sub {
    my $params = params();
  };
  get '/add' => sub {
    my $params = params();

    my $errors = var('errors') || [];
    my $object = var('object') || parse_request();
    
    template 'request/add',{
      obj => $object,errors => $errors
    };
  };
  post '/add' => sub {
    my $params = params();

    my $object = parse_request(); 

    my($data,%extra) = validator_request()->validate(%$params);
    if(validator_request()->has_errors()){
      my @errors;
      my $errs = validator_request()->clear_errors();
      push @errors,@{ resolve_validator_errors($errs) };

      var errors => \@errors;
      var object => $object;
      forward '/request/add',$params,{ method => "GET" };

    }else{
      $object->{status} = "NEW";
      #add to database
      $object = requests()->add($object);
      #add to index
      my $idx = indexable_request()->to_index_record($object);
      index_requests()->add($idx);
      index_requests()->commit();
      #add to message queue for further processing
      queue(to_json({
        controller => 'request',
        func => 'add',
        id => $object->{_id} 
      },{pretty => 0}));

      return to_json($object);
    }    
  };
 
};
sub queue {
  my $msg = $_[0];
  state $subscribed = 0;
  unless($subscribed){
    if(is_hash_ref(config->{stomp}->{subscribe}) && is_string(config->{stomp}->{subscribe}->{destination})){
      stomp()->subscribe(config->{stomp}->{subscribe});
    }
    $subscribed = 1;
  }
  stomp_send {
    destination => config->{stomp}->{destination},
    body => $msg
  };

}
sub parser_request {
  state $parser_request = do {
    my $record_resolver = require_package(config->{record_resolver}->{package})->new(
      %{ config->{record_resolver}->{options} }
    );
    my $availability_resolver = require_package(config->{availability_resolver}->{package})->new(
      %{ config->{availability_resolver}->{options} }
    );
    Circulation::Parser::Request->new(record_resolver => $record_resolver,availability_resolver => $availability_resolver);
  };
}
sub parse_request {
  my $params = params();
  my $session = session();
  my $env = request->env();
  parser_request->parse(
    params => $params,
    session => $session,
    env => $env
  );
}

sub validator_request {
  state $validator_request = validator("request");
}
sub indexable_request {
  state $indexable_request = Circulation::Indexable::Request->new;
}

hook before_template_render => sub {
  my $tokens = shift;
  $tokens->{catmandu_config} = Catmandu->config;
};

1;

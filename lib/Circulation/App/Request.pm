package Circulation::App::Request;
our $VERSION = '1.0';
use Catmandu::Sane;
use Catmandu;
use Dancer qw(:syntax);
use Dancer::Plugin::Lexicon;
use Circulation qw(:all);
use Circulation::Parser::Request;
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
      return to_json($object);
    }    
  };
 
};

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

hook before_template_render => sub {
  my $tokens = shift;
  $tokens->{catmandu_config} = Catmandu->config;
};

1;

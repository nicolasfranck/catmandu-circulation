package Circulation::App::Request;
our $VERSION = '1.0';
use Catmandu::Sane;
use Catmandu;
use Dancer qw(:syntax);
use Dancer::Plugin::Lexicon;
use Dancer::Plugin::Stomp;
use Circulation qw(:all);
use Circulation::Indexable::Request;
use Catmandu::Util qw(:is :array require_package);
use Try::Tiny;
use POSIX qw(strftime);

#list records, and filter them by query
prefix '/request' => sub {

  #this route must be protected!
  get '/' => sub {
    my $params = params();

    my $query = $params->{q};
    $query = is_string($query) ? $query:"*:*";
    my $start = $params->{start};
    $start = is_natural($start) ? $start:0;
    my $limit = $params->{limit};
    $limit = is_natural($limit) ? $limit:100;

    my $user = session('user');
    my $fq;
    if($user && config->{authen_filter}->{$user->{login}}) {
      $fq = config->{authen_filter}->{$user->{login}};
    }else{
      $fq = "NOT *:*";
    }

    my %search = ( query => $query,start => $start,limit => $limit => sort => 'date_dt desc', fq => $fq);    

    $params->{$_} = $search{$_} for(keys %search);

    my $result = index_requests()->search(%search,reify => requests());

    #TODO: aantal print jobs voor elk record
    for my $hit(@{ $result->hits }){
      $hit->{'print'}->{count} = 0;
    }

    my $today = strftime "%Y-%m-%dT%H:%M:%S.999Z" , gmtime(time);
    my $yesterday = strftime "%Y-%m-%dT%H:%M:%S.999Z" , gmtime(time - 3600*24*2);

    template 'request/list.tt', { today => $today,yesterday => $yesterday,result => $result};
  };
  get '/add' => sub {
    my $params = params();

    my $errors = var('errors') || [];
    my $object = var('object') || parse_request();
 
    #return to_json($object);   
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
sub parse_request {
  my($self,%opts)=@_;
  my $params = params();
  my $session = session();

  my $object = {
    created => time,
    modified => time
  };

  $object->{request}->{remote_addr} = request->remote_address;

  my %main_param = (id=>1);

  foreach my $param_key(keys %$params){
    next unless ($param_key =~ /^_/);
    my $name = $param_key;
    $name =~ s/^_//;

    if($main_param{$name}){
      $object->{$name} = $params->{$param_key};
    }else{
      $object->{request}->{$name} = $params->{$param_key};
    }
  }

  if($object->{request}->{bibcall}){
    my ($library,$callnumber) = split(/;/,$object->{request}->{bibcall},2);
    $object->{request}->{library} = $library;
    $object->{request}->{callnr}  = $callnumber;
    delete $object->{request}->{bibcall};
  }

  if($object->{request}->{record}){
    my $record = record_resolver()->resolve($object->{request}->{record});
    $object->{record} = $record;
  }

  my $items = $object->{record}->{items};

  if(defined $items){
    if(@$items == 1){
      my $library    = $items->[0]->{library};
      my $callnumber = $items->[0]->{location};
      $callnumber ||= '---';
      my $holding    = $items->[0]->{holding};
      my $barcode    = $items->[0]->{barcode};
      my $action = $items->[0]->{action};

      $object->{request}->{library} = $library;
      $object->{request}->{callnr}  = $callnumber;
      $object->{request}->{holding} = $holding;
      $object->{request}->{barcode} = $barcode;
      $object->{request}->{action} = $action;

      $params->{_library} = $library;
      $params->{_callnr} = $callnumber;
      $params->{_holding} = $holding;
      $params->{_barcode} = $barcode;
    }
    else {
      foreach my $l (@$items) {
        my $library    = $l->{library};
        my $callnumber = $l->{location};
        my $holding    = $l->{holding};
        my $barcode    = $l->{barcode};
        my $action = $l->{action};

        if($object->{request}->{library} eq $library && $object->{request}->{callnr} eq $callnumber){
          $object->{request}->{library} = $library;
          $object->{request}->{callnr}  = $callnumber;
          $object->{request}->{holding} = $holding;
          $object->{request}->{barcode} = $barcode;
          $object->{request}->{action} = $action;

          $params->{_library} = $library;
          $params->{_callnr} = $callnumber;
          $params->{_holding} = $holding;
          $params->{_barcode} = $barcode;
          
          last;

        }
      }
    }
  }

  if(defined $object->{request}->{barcode} && length($object->{request}->{barcode})){
    my $avail = availability_resolver()->resolve($object->{request}->{barcode});
    $object->{record}->{availability} = $avail->{loan} if $avail;
  }
  
  if($session && defined($session->{remember}) && $session->{remember} eq 'on'){
    $params->{_name} = $session->{name} unless $params->{_name};
    $params->{_contact} = $session->{contact} unless $params->{_contact};
    $params->{_uid} = $session->{uid} unless $params->{_uid};
    $params->{_remember} = 'on';
  }

  return $object;
}
1;

package Circulation;
use Catmandu::Sane;
use Catmandu;
use Catmandu::Util qw(:is :check require_package :array data_at);
use Try::Tiny;

use Exporter qw(import);
our @stores = qw(requests emails libraries prints sessions sms templates index_requests meercat);
our @validator = qw(validator resolve_validator_errors);
our @alephx = qw(alepx);
our @EXPORT_OK = (@stores,@validator,@alephx);
our %EXPORT_TAGS = (
  all => [@EXPORT_OK],
  stores => \@stores,
  alephx => \@alephx
);

use Data::Validator;
use Mouse::Util::TypeConstraints;
subtype 'NonEmptyStr' => as 'Str' => where { is_string($_) };
subtype 'AlphaNumeric' => as 'NonEmptyStr' => where { $_ =~ /^[a-zA-Z0-9_\-]+$/o };
subtype 'RecordId' => as 'NonEmptyStr' => where { $_ =~ /^\w{5}:\d{9}$/o };

sub new { bless {},shift }

#configuration
sub config {
  state $config = Catmandu->config;
}

#stores
sub documents_store_name {
  state $documents_store_name = do {
    Catmandu->config->{documents_store_name} || "default";
  };
}
sub index_store_name {
  state $index_store_name = do {
    Catmandu->config->{index_store_name} || "index";
  };

}
sub meercat_store_name {
  state $meercat_store_name = do {
    Catmandu->config->{meercat_store_name} || "meercat";
  };

}
sub meercat {
  state $meercat = Catmandu->store(meercat_store_name())->bag();
}
sub index_requests {
  state $index_requests = Catmandu->store(index_store_name())->bag("requests");
}
sub requests {
  state $requests = Catmandu->store(documents_store_name())->bag("requests");
}
sub emails {
  state $emails = Catmandu->store(documents_store_name())->bag("emails");
}
sub libraries {
  state $libraries = Catmandu->store(documents_store_name())->bag("libraries");
}
sub prints {
  state $prints = Catmandu->store(documents_store_name())->bag("prints");
}
sub sessions {
  state $sessions = Catmandu->store(documents_store_name())->bag("sessions");
}
sub sms {
  state $sms = Catmandu->store(documents_store_name())->bag("sms");
}
sub templates {
  state $templates = Catmandu->store(documents_store_name())->bag("templates");
}
sub validator {
  state $instances = {};
  my $name = shift;
  $name ||= "default";

  $instances->{$name} ||= do{
    my $config = Catmandu->config();
    my $required_keys = $config->{$name}->{required_keys} // [];
    my $optional_keys = $config->{$name}->{optional_keys} // [];

    my %args = ();
    for my $key(@$required_keys){
      $args{$key} = {
        isa => $config->{$name}->{isa}->{$key}
      }
    }
    for my $key(@$optional_keys){
      $args{$key} = {
        isa => $config->{$name}->{isa}->{$key},
        optional => 1
      }
    }
    Data::Validator->new(%args)->with('NoThrow')->with('AllowExtra');
  };
}
sub resolve_validator_errors {
  my $errs = shift;
  my @errors;
  for my $err(@$errs){
    given($err->{type}){
      when("MissingParameter"){
        push @errors,lc($err->{name})."_required";
      }
      when("InvalidValue"){
        push @errors,lc($err->{name})."_invalid";
      }
      when("UnknownParameter"){
        push @errors,lc($err->{name})."_invalid";
      }
      when("InvalidValue"){
        push @errors,lc($err->{name})."_invalid";
      }
    }
  }
  \@errors;
}
sub alephx {
  state $instances = {};
  my($class,$name) = @_;

  my $key = $name || "default";

  $instances->{$key} ||= do {
    my($i);
    my $package = data_at(["alephx",$key,"package"],Catmandu->config);
    my $options = data_at(["alephx",$key,"options"],Catmandu->config) // {};
    check_string($package);
    check_hash_ref($options);
    $i = require_package($package)->new(%$options);
    Catmandu::BadArg->throw("unknown alephx '$key'") unless $i;
    $i;
  };
}
1;

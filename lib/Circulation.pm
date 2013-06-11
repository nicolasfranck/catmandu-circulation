package Circulation;
use Catmandu::Sane;
use Catmandu;
use Catmandu::Util qw(:is :check require_package :array);
use Try::Tiny;

use Exporter qw(import);
our @stores = qw(requests emails libraries prints sessions sms templates);
our @validator = qw(validator resolve_validator_errors);
our @EXPORT_OK = (@stores,@validator);
our %EXPORT_TAGS = (
  all => [@EXPORT_OK],
  stores => \@stores
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
        push @errors,"DATA_".uc($err->{name})."_REQUIRED";
      }
      when("InvalidValue"){
        push @errors,"DATA_".uc($err->{name})."_INVALID";
      }
      when("UnknownParameter"){
        push @errors,"DATA_".uc($err->{name})."_INVALID";
      }
      when("InvalidValue"){
        push @errors,"DATA_".uc($err->{name})."_INVALID";
      }
    }
  }
  \@errors;
}
1;

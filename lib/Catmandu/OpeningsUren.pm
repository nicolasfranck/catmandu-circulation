package Catmandu::OpeningsUren;
use Catmandu::Sane;
use Catmandu::Util qw(:check :is);
use Carp qw(confess);
use Moo;
use LWP::UserAgent;
use URI::Escape qw(uri_escape);
use JSON;

our $VERSION = "0.1";

has base_url => (
  is => 'ro',
  required => 1
);

has _ua => (
  is => 'ro',
  lazy => 1,
  default => sub {
    LWP::UserAgent->new(
      cookie_jar => {}
    );
  }
);

sub _validate_web_response {
  my($self,$res) = @_;
  $res->is_error && confess($res->content."\n");
}
sub _request {
  my($self,$path,$params,$method)=@_;
  $method ||= "GET";
  my $res;
  if(uc($method) eq "GET"){
    $res = $self->_get($path,$params);
  }elsif(uc($method) eq "POST"){
    $res = $self->_post($path,$params);
  }else{
    confess "method $method not supported";
  }
  $self->_validate_web_response($res);

  $res;
}
sub _construct_params_as_array {
  my($self,$params) = @_;
  my @array = ();
  for my $key(keys %$params){
    if(is_array_ref($params->{$key})){
      for my $val(@{ $params->{$key} }){
        push @array,uri_escape($key) => uri_escape($val);
      }
    }else{
      push @array,uri_escape($key) => uri_escape($params->{$key});
    }
  }
  return \@array;
}
sub _post {
  my($self,$path,$data)=@_;
  $self->_ua->post($self->base_url.$path,$self->_construct_params_as_array($data));
}
sub _construct_query {
  my($self,$data) = @_;
  my @parts = ();
  for my $key(keys %$data){
    if(is_array_ref($data->{$key})){
      for my $val(@{ $data->{$key} }){
        push @parts,uri_escape($key)."=".uri_escape($val);
      }
    }else{
      push @parts,uri_escape($key)."=".uri_escape($data->{$key});
    }
  }
  join("&",@parts);
}
sub _get {
  my($self,$path,$data)=@_;
  my $query = $self->_construct_query($data) || "";
  $self->_ua->get($self->base_url.$path."?$query");
}
sub _json {
  state $json = JSON->new->utf8;
}

#libraries
#
sub libraries {
  my($self,$params) = @_;
  $params ||= {};  
  $params->{pretty} = 0;
  my $res = $self->_request("/libraries.json",$params,"GET");  
  $self->_json->decode($res->content);
}
sub library {
  my($self,$params) = @_;
  $params ||= {};
  $params->{pretty} = 0;
  my $res = $self->_request("/libraries/".$params->{library}.".json",$params,"GET");  
  $self->_json->decode($res->content);
}
=head1 NAME
    

=head1 SYNOPSIS

=head1 SEE ALSO

L<Catmandu>

=head1 AUTHOR

Nicolas Franck , C<< <nicolas.franck at ugent.be> >>
    
=cut

1;

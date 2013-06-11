package RecordResolver;

sub new {
    my $pkg = shift;
    my (%opt) = @_;
    return bless { %opt } , $pkg;
}

#overwrite 
# return a perl hash with your content
sub resolve {
    my $self = shift;
    my $id   = shift;
}

1;
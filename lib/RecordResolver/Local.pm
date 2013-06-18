package RecordResolver::Local;
use Catmandu::Sane;
use Circulation qw(records);
use Catmandu::Fix;
use Moo;


sub card_fixer {
  state $card_fixer = Catmandu::Fix->new(
    fixes => [
      "marc_map('CATf','keep.card')",
      "marc_map('852c','keep.library')",
      "retain_field('keep')",
      "move_field('keep.card','card')",
      "move_field('keep.library','library')",
      "remove_field('keep')"
    ]
  );
}
sub resolve {
  my($self,$id) = @_;

  return $self->resolve_card($id) if ($id =~ /^rug0(2|3)/);

  my $res = $self->resolve_default($id);    

  # Little Boopsie hack..if record can't be found it's probably a ser01
  # try again with rug01
  unless ($res) {
    $id =~ s/^\w+/ser01/;
    $res = $self->resolve_default($id);
  }

  return $res;
}

sub resolve_card {
  my($self,$id)=@_;

  my $record = records()->get($id);
  return unless $record;

  $record = card_fixer()->fix($record);

  if($id =~ /^(\w+):.*/){
    $record->{card_url} = "/meercat/x/stream?source=$1&id=" . $record->{card}; 
  }
  
  return $record;
}
sub default_fixer {
  state $default_fixer = Catmandu::Fix->new(
    fixes => [
      "marc_map('245','title','-join' => ' ')",
      "marc_map('100a','author','-join' => ' ')",
      "marc_map('260b','publisher')",
      "marc_map('260c','dateIssued')",
      "marc_map('300','description','-join' => ' ')",
      "marc_map('020','isbn')",
      "marc_map('022','issn')",
      "marc_map('490','series')"
    ]
  );
}
sub resolve_default {
  my($self,$id)=@_;

  my $record = records->get($id);
  return unless $record;

  $record = default_fixer()->fix($record);

  return $record;
}

with 'RecordResolver';

1;

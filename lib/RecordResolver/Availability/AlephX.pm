package RecordResolver::Availability::AlephX;
use Catmandu::Sane;
use Catmandu::AlephX;
use Moo;
use Try::Tiny;
use Circulation qw(alephx);

sub resolve {
  my($self,$id);
  
  my(@items,@errors);

  my $res = {
    record => $id,
    items => \@items,
    errors => \@errors
  };
  try{

    my($source,$fSYS) = split(':',$id || "");
    #opgelet: alephx gebruikt enkel 1ste 9 cijfers van doc_number. De rest wordt genegeerd.
    my $r = alephx()->item_data(base => $source,doc_number => $fSYS);
    if($r->is_success){
      for my $item(@{ $r->items() }){
        $item->{$_} = $item->{$_}->[0] for keys %$item;
        push @items,$item;
      }
    }else{
      push @errors,$r->error;
    }

  }catch{
    push @errors,$_;
  };

  $res;
}

with 'RecordResolver';

1;

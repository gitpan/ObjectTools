package Object::new ;
$VERSION = 1.1 ;

; use 5.006_001
; use strict
; use Carp


; sub import
   { my ($pkg, %args) = @_
   ; my $callpkg = caller
   ; my $n = $args{name} || 'new'
   ; $args{init} &&= [ $args{init} ]
                     unless ref $args{init} eq 'ARRAY'
   ; my $init_default = '_init'
   ###### CONSTRUCTOR ######                  # exported sub
   ; local *N = eval "*$callpkg\::$n"
   ; *N = sub
           { my $c = shift
           ; croak qq(Can't call method "$n" on a reference)
                   if ref $c
           ; croak qq(Odd number of arguments for "$c->$n")
                   if @_ % 2
           ; my $o = bless {}, $c
           ; while ( my ($p, $v) = splice @_, 0, 2 )
              { $o->can($p)
                or croak qq(No such property "$p")
              ; { local $Carp::Internal{+__PACKAGE__} = 1
                ; $o->$p( $v )
                }
              }
           ; if ( $o->can( $init_default )
                &&! $args{init}
                )
              { $args{init} = [ $init_default ]
              }
           ; foreach my $m ( @{$args{init}} )
              { $o->$m(@_)
              }
           ; $o
           }
   }


; 1

__END__

=head1 NAME

Object::new - Pragma to implement constructor methods

=head1 VERSION 1.1

Included in ObjectTools 1.1 distribution.

=head1 SYNOPSIS

=head2 Class

    package MyClass ;
    
    # implement constructor without options
    use Object::new ;
    
    # this will be called by default if defined
    sub _init
    {
      my ($s, @args) = @_
      ....
    }
    
    # with options
    use Object::new  name  => 'new_object'
                     init  => [ qw( init1 init2 ) ] ;
    

=head2 Usage

    my $object = MyClass->new(digits => '123');

=head1 DESCRIPTION

This pragma easily implements lvalue constructor methods for your class.

You can completely avoid to write the constructor by just using it and eventually declaring the name and the init methods to call.

=head1 INSTALLATION

=over

=item Prerequisites

    Perl version >= 5.6.1

=item CPAN

    perl -MCPAN -e 'install ObjectTools'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head2 OPTIONS

=over

=item name

The name of the constructor method. If you omit this option the 'new' name will be used by default.

=item init

use this option if you want to call other method in your class to further initialize the object. You can group method by passing a reference to an array containing the methods names.

After the assignation and validation of the properties, the initialization methods in the C<init> option will be called. Each init method will receive the blessed object passed in C<$_[0]> and the other (original) parameter in the remaining C<@_>.

=back

=head1 BUGS

None known, but the module is not completely tested.

=head1 CREDITS

Thanks to Juerd Waalboer (http://search.cpan.org/author/JUERD) that with its I<Attribute::Property> inspired the creation of this distribution.


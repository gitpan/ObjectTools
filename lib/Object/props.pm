package Object::props ;
$VERSION = 1.0 ;

; use 5.006_001
; use strict
; use Carp

; sub import
   { my ($pkg, @args) = @_
   ; my $callpkg = caller
   ; foreach my $item ( @args )                  # foreach items
      { $item = { name => $item }
                unless ref $item eq 'HASH'
      ; $$item{name} = [ $$item{name} ]
                       unless ref $$item{name} eq 'ARRAY'
      ; foreach my $n ( @{$$item{name}} )        # foreach property
         {
         ###### DEFAULT ######
         ; my $default = ''
         ; if ( defined $$item{default} )        # if default key
            { $default = $$item{default}         # set the default
            ; if ( defined $$item{validation} )  # if validation key
               { local $_ = $default             # set $_
               ; $$item{validation}( $_[0]       # check value (only if def key)
                                   , $_
                                   )
                 or croak qq(Invalid default value for "$n" property)
               ; $default = $_                   # set default
               }
            }
         ###### ACCESSOR ######                  # exported sub
         ; local *P = eval "*$callpkg\::$n"
         ; *P = sub : lvalue
                 { croak qq(Too many arguments for "$n" property)
                         if @_ > 2
                         
                 ; $_[0]{$n} = $default             # run time assignation
                               unless defined $_[0]{$n}
                                  
                 ###### PROTECTION ######           # only included if protected
                 ; my $write_protected = 0
                 ; if (   $$item{protected}
                      &&! $Object::props::force
                      )
                    { my $caller = (caller)[0] eq 'Object::new'
                                   ? (caller(1))[0]
                                   : (caller)[0]
                    ; $write_protected = $caller->can($n)
                                         ? 0
                                         : 1
                    }
                 
                 ###### TIE ######                  # only included if...
                 ; if ( defined $$item{validation}  # validate value (could croak)
                      || $write_protected           # must croak
                      )
                    { tie $_[0]{$n}                 # scalar
                        , $pkg                      # class
                        , $_[0]                     # [0] object ref
                        , $n                        # [1] prop name
                        , $$item{validation}        # [2] validation subref
                        , $write_protected          # [3] bool
                    }
                 ###### END ######                  # lvalue always included
                 ; @_ == 2
                   ? ( $_[0]{$n} = $_[1] )          # old fashioned ()
                   :   $_[0]{$n}                    # lvalue assignment
               
                 } # end property sub
              
         } # end foreach property
         
      } # end foreach item
      
   }

; sub TIESCALAR
   { bless \@_, shift
   }
   
; sub FETCH
   { $_[0][0]{$_[0][1]}
   }

; sub STORE
   { local $_ = $_[1]
   ; if ( $_[0][3] )             # write protected
      { $_[0][3] = 0             # reset flag in case of eval
      ; croak qq("$_[0][1]" is a read-only property)
      }
             
   ; if ( defined $_[0][2] )     # validation subref
      { $_[0][2]( $_[0][0]
                , $_
                )
        or croak qq(Invalid value for "$_[0][1]" property)
      }
   ; $_[0][0]{$_[0][1]} = $_   # store
   }

; 1

__END__

=head1 NAME

Object::props - Pragma to implement lvalue accessors with options

=head1 VERSION 1.0

Included in ObjectTools 1.0 distribution.

=head1 SYNOPSIS

=head2 Class

    package MyClass ;
    
    # implement constructor without options
    use Object::new ;
    
    # just accessors without options (list of strings)
    use Object::props @prop_names ;
    
    # a property with validation and default (list of hash refs)
    use Object::props { name       => 'digits',
                        validation => sub{ /^\d+\z/ }       # just digits
                        default    => 10
                      } ;
    
    # a group of properties with common full options
    use Object::props { name       => \@other_prop_names,   # array ref
                        default    => 'something' ,
                        validation => sub{ /\w+/ }
                        protected  => 1
                      } ;
                      
    # all the above in just one step (list of strings and hash refs)
    use Object::props @prop_names ,
                      { name       => 'digits',
                        validation => sub{ /^\d+\z/ }
                        default    => 10
                      } ,
                      { name       => \@other_prop_names,
                        default    => 'something' ,
                        validation => sub{ /\w+/ }
                        protected  => 1
                      } ;
    

=head2 Usage

    my $object = MyClass->new(digits => '123');
    
    $object->digits    = '123';
    
    $object->digits('123');
    
    my $d = $object->digits;  # $d == 123
    
    undef $object->digits     # $object->digits == 10 (default)
    
    # This would croak
    $object->digits    = "xyz";


=head1 DESCRIPTION

This pragma easily implements lvalue accessor methods for the properties of your object (I<lvalue> means that you can create a reference to it, assign to it and apply a regex to it).

You can completely avoid to write the accessor by just declaring the names and eventually the default value, validation code and other option of your properties.

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

The name of the property is used as the identifier to create the accessor method, and as the key of the blessed object hash.

Given 'my_prop' as the property name:

    $object->my_prop = 10 ;  # assign 10 to $object->{my_prop}
    $object->my_prop( 10 );  # assign 10 to $object->{my_prop}
    
    # same thing if MyClass::new is implemented
    # by the Object::new pragma
    
    $object = MyClass->new( my_prop => 10 );

You can group properties that have the same set of option by passing a reference to an array containing the names. If you don't use any option you can pass a list of plain names as well. See L<"SYNOPSYS">.

=item default

The property will be initially set to the I<default value>. If you don't set any C<default> option the empty string will be used as default. You can reset a property to its default value by assigning it the undef value.

    # this will reset the property to its default
    $object->my_prop = undef ;
    
    # this works as well
    undef $object->my_prop ;

If any C<validation> option is set, then the I<default value> is validated at compile time. If no C<default> option is set, then the empty string is used bypassing the C<validation> sub.

=item validation

You can set a code reference to validate a new value. If you don't set any C<validation> option, no validation will be done on the assignment.

In the validation code, the object is passed in C<$_[0]> and the value to be
validated is passed in C<$_[1]> and for regexing convenience it is aliased in C<$_>. Assign to C<$_> in the validation code to change the actual imput value.

    # web color validation
    use Object::props { name       => 'web_color'
                        validation => sub { /^#[0-9A-F]{6}$/ }
                      }
    
    # this will uppercase all input value
    use Object::props { name       => 'uppercase_it'
                        validation => sub { $_ = uc }
                      }
    # this would croak
    $object->web_color = 'dark gray'
    
    # when used
    $object->uppercase_it = 'abc' # real value will be 'ABC'

The validation code should return true on success and false on failure. Croak explicitly if you don't like the default error message.

=item protected

Set this option to a true value and the property will be turned I<read-only> when used from outside its class or sub-classes. This allows you to normally read and set the property from your class but it will croak if your user tries to set it.

=back

=head1 BUGS

None known, but the module is not completely tested.

=head1 CREDITS

Thanks to Juerd Waalboer (http://search.cpan.org/author/JUERD) that with its I<Attribute::Property> inspired the creation of this distribution.



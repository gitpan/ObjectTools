use ExtUtils::MakeMaker;

WriteMakefile
(
  NAME             => 'ObjectTools',
  VERSION_FROM     => 'lib/Object/props.pm',
  ($] ge '5.005')
     ? ('AUTHOR'   => 'Domizio Demichelis <dd\@4pro.net>',
        'ABSTRACT' => 'Pragmas to create constructor and accessors' )
                      
     : (),
);


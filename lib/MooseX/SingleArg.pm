package MooseX::SingleArg;
{
  $MooseX::SingleArg::VERSION = '0.03';
}
use Moose ();
use Moose::Exporter;

=head1 NAME

MooseX::SingleArg - No-fuss instantiation of Moose objects using a single argument.

=head1 SYNOPSIS

    package Person;
    use Moose;
    
    use MooseX::SingleArg;
    
    single_arg 'name';
    
    has name => ( is=>'ro', isa=>'Str' );
    
    my $john = Person->new( 'John Doe' );
    print $john->name();

=head1 DESCRIPTION

This module provides a role and declarative sugar for allowing Moose instances
to be constructed with a single argument.  Your class must use this module and
then use the single_arg method to declare which of the class's attributes will
be assigned the single argument value.

If the class is constructed using the typical argument list name/value pairs,
or with a hashref, then things work as is usual.  But, if the arguments are a
single non-hashref value then that argument will be assigned to whatever
attribute you have declared.

The reason for this module's existence is that when people want this feature
they usually find L<Moose::Cookbook::Basics::Recipe10> which asks that something
like the following be written:

    around BUILDARGS => sub{
        my $orig = shift;
        my $self = shift;
        
        if (@_==1 and ref($_[0]) ne 'HASH') {
            return $self->$orig( foo => $_[0] );
        }
        
        return $self->$orig( @_ );
    };

The above is complex boilerplate for a simple feature.  This module aims to make
it simple and fool-proof to support single-argument Moose object construction.

=head1 FORCING SINGLE ARG PROCESSING

An optional force parameter may be specified:

    single_arg name => (
        force => 1,
    );

This causes constructor argument processing to only work in single-argument mode.  If
more than one argument is passed then an error will be thrown.  The benefit of forcing
single argument processing is that hashrefs may now be used as the value of the single
argument when force is on.

=cut

use Carp qw( croak );

Moose::Exporter->setup_import_methods(
    with_meta => [ 'single_arg' ],
);

sub single_arg {
    my ($meta, $arg, %params) = @_;

    my $class = $meta->name();
    croak "A single arg has already been declared for $class" if $class->_has_single_arg();

    $class->_single_arg( $arg );

    foreach my $param (keys %params) {
        my $method = '_' . $param . '_single_arg';
        croak("Unknown single_arg parameter $param") if !$class->can($method);
        $class->$method( $params{$param} );
    }

    return;
}

sub init_meta {
    shift;
    my %args = @_;

    Moose->init_meta( %args );

    my $class = $args{for_class};

    Moose::Util::MetaRole::apply_base_class_roles(
        for_class => $class,
        roles => [ 'MooseX::SingleArg::Role' ],
    );

    return $class->meta();
}

{
    package MooseX::SingleArg::Role;
{
  $MooseX::SingleArg::Role::VERSION = '0.03';
}
    use Moose::Role;

    use Carp qw( croak );
    use MooseX::ClassAttribute;

    class_has _single_arg => (
        is        => 'rw',
        isa       => 'Str',
        predicate => '_has_single_arg',
    );

    class_has _force_single_arg => (
        is        => 'rw',
        isa       => 'Bool',
    );

    around BUILDARGS => sub{
        my $orig = shift;
        my $class = shift;

        my $single_arg = $class->_single_arg();
        croak("single_arg() has not been called for $class") if !$single_arg;

        my $force = $class->_force_single_arg();
        croak("$class accepts only one argument for $single_arg") if $force and @_>1;

        if (@_==1 and ($force or ref($_[0]) ne 'HASH')) {
            return $class->$orig( $single_arg => $_[0] );
        }

        return $class->$orig( @_ );
    };
}

1;
__END__

=head1 SEE ALSO

L<MooseX::OneArgNew> solves the same problem that this module solves.  I considered using OneArgNew
for my own needs, but found it oddly combersom and confusing.  Maybe thats just me, but I hope that
this module's design is much simpler to comprehend and more natural to use.

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

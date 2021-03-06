package mop::method;

use v5.16;
use warnings;

use mop::util qw[ init_attribute_storage ];
use Scalar::Util 'weaken';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use parent 'mop::object', 'mop::observable';

init_attribute_storage(my %name);
init_attribute_storage(my %body);
init_attribute_storage(my %associated_meta);

sub new {
    my $class = shift;
    my %args  = @_;
    my $self = $class->SUPER::new;
    $name{ $self } = \($args{'name'});
    $body{ $self } = \($args{'body'});
    $self;
}

# temporary, for bootstrapping
sub clone {
    my $self = shift;
    return ref($self)->new(name => $self->name, body => $self->body);
}

sub name { ${ $name{ $_[0] } } }
sub body { ${ $body{ $_[0] } } }

sub associated_meta { $associated_meta{ $_[0] } }
sub set_associated_meta {
    $associated_meta{ $_[0] } = $_[1];
    weaken($associated_meta{ $_[0] });
}

sub execute {
    my ($self, $invocant, $args) = @_;

    $self->fire('before:EXECUTE' => $invocant, $args);

    my @result;
    my $wantarray = wantarray;
    if ( $wantarray ) {
        @result = $self->body->( $invocant, @$args );
    } elsif ( defined $wantarray ) {
        $result[0] = $self->body->( $invocant, @$args );
    } else {
        $self->body->( $invocant, @$args );
    }

    $self->fire('after:EXECUTE' => $invocant, $args, \@result);

    return $wantarray ? @result : $result[0];
}

our $METACLASS;

sub __INIT_METACLASS__ {
    return $METACLASS if defined $METACLASS;
    require mop::class;
    $METACLASS = mop::class->new(
        name       => 'mop::method',
        version    => $VERSION,
        authority  => $AUTHORITY,
        superclass => 'mop::object'
    );

    $METACLASS->add_attribute(mop::attribute->new(
        name    => '$!name',
        storage => \%name
    ));

    $METACLASS->add_attribute(mop::attribute->new(
        name    => '$!body',
        storage => \%body
    ));

    $METACLASS->add_attribute(mop::attribute->new(
        name    => '$!associated_meta',
        storage => \%associated_meta
    ));

    $METACLASS->add_method( mop::method->new( name => 'new', body => \&new ) );

    $METACLASS->add_method( mop::method->new( name => 'name',                body => \&name                ) );
    $METACLASS->add_method( mop::method->new( name => 'body',                body => \&body                ) );
    $METACLASS->add_method( mop::method->new( name => 'associated_meta',     body => \&associated_meta     ) );
    $METACLASS->add_method( mop::method->new( name => 'set_associated_meta', body => \&set_associated_meta ) );

    $METACLASS->add_method( mop::method->new( name => 'execute', body => \&execute ) );

    $METACLASS;
}

1;

__END__

=pod

=head1 NAME

mop::method

=head1 DESCRIPTION

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little <stevan@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut






package Test::Mock::LWP::Conditional;

use 5.008001;
use strict;
use warnings;
use LWP::UserAgent;
use Scalar::Util qw(blessed refaddr);
use Sub::Install qw(install_sub);
use Class::Method::Modifiers qw(install_modifier);
use Test::Mock::LWP::Conditional::Container;

our $VERSION = '0.01';
$VERSION = eval $VERSION;

our $Stubs = +{ __GLOBAL__ => +{} };

sub _set_stub {
    my ($key, $uri, $res) = @_;

    $Stubs->{$key} ||= +{};
    $Stubs->{$key}->{$uri} ||= Test::Mock::LWP::Conditional::Container->new;

    $Stubs->{$key}->{$uri}->add($res);
}

sub _get_stub {
    my ($key, $uri) = @_;

    if (exists $Stubs->{$key} && exists $Stubs->{$key}->{$uri}) {
        return $Stubs->{$key}->{$uri};
    }
    elsif (exists $Stubs->{__GLOBAL__}->{$uri}) {
        return $Stubs->{__GLOBAL__}->{$uri};
    }
}

sub stub_request {
    my ($self, $uri, $res) = @_;
    my $key = blessed($self) ? refaddr($self) : '__GLOBAL__';
    _set_stub($key, $uri, $res);
}

sub reset_all {
    $Stubs = +{ __GLOBAL__ => +{} };
}

{ # LWP::UserAgent injection
    install_modifier('LWP::UserAgent', 'around', 'simple_request', sub {
        my $orig = shift;
        my ($self, $req, @rest) = @_;

        my $stub = _get_stub(refaddr($self), $req->uri);
        return $stub ? $stub->execute($req) : $orig->(@_);
    });

    install_sub({
        code => __PACKAGE__->can('stub_request'),
        into => 'LWP::UserAgent',
        as   => 'stub_request',
    });
}

1;

=head1 NAME

Test::Mock::LWP::Conditional - A module that ...

=head1 SYNOPSIS

    use Test::Mock::LWP::Conditional;

=head1 DESCRIPTION

This module stubs out LWP::UserAgent's request.

=head1 METHODS

=over 4

=item * stub_request($uri, $res)

=item * reset_all

Clear all stub requests.

=back

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Mock::LWP>, L<Test::Mock::LWP::Dispatch>, L<Test::MockHTTP>, L<Test::LWP::MockSocket::http>

L<LWP::UserAgent>

=cut

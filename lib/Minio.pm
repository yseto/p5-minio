package Minio;
use parent qw(Amazon::S3);
use Carp;
use Digest::SHA qw/sha256_hex/;
use Net::Amazon::Signature::V4;
use Time::Piece;

sub _send_request {
    my $self = shift;
    my $request;
    if (@_ == 1) {
        $request = shift;
    }
    else {
        $request = $self->_make_request(@_);
    }

    my $response = $self->_do_http($request);
    my $content  = $response->content;

    if ($response->content_type ne 'application/xml' &&
        $response->content_type ne 'text/xml') {
        return $content;
    }
    return unless $content;
    return $self->_xpc_of_content($content);
}

sub _make_request {
    my ($self, $method, $path, $headers, $data, $metadata) = @_;
    croak 'must specify method' unless $method;
    croak 'must specify path'   unless defined $path;
    $headers ||= {};
    $data = '' if not defined $data;
    $metadata ||= {};

    my $http_headers = $self->_merge_meta($headers, $metadata);

    if (not $http_headers->header('Date')) {
        my $t = gmtime->strftime("%Y%m%dT%H%M%SZ");
        $http_headers->header('Date' => $t);
    }

    my $protocol = $self->secure ? 'https' : 'http';
    my $host     = $self->host;
    my $url      = "$protocol://$host/$path";
    if ($path =~ m{^([^/?]+)(.*)} && 0) {
        $url = "$protocol://$1.$host$2";
    }

    my $request = HTTP::Request->new($method, $url, $http_headers, $data);
    my $sig = Net::Amazon::Signature::V4->new( $self->aws_access_key_id, $self->aws_secret_access_key, "us-east-1", "s3" );
    
    $request->header(host => $self->host);
    $request = $sig->sign( $request );
    $request->header('x-amz-content-sha256' => sha256_hex($data));

#   my $req_as = $request->as_string;
#   $req_as =~ s/[^\n\r\x20-\x7f]/?/g;
#   $req_as = substr( $req_as, 0, 1024 ) . "\n\n";
#   warn $req_as;

    return $request;
}

sub _urlencode { $_[1]; }

1;

__END__


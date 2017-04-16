#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use Plack::Builder;
use Plack::Request;
use Plack::Response;

use lib "$FindBin::Bin/lib";
use Minio;

my $s3 = Minio->new({
    aws_access_key_id     => $ENV{MINIO_ENV_MINIO_ACCESS_KEY},
    aws_secret_access_key => $ENV{MINIO_ENV_MINIO_SECRET_KEY},
    host => $ENV{MINIO_PORT_9000_TCP_ADDR}.":".$ENV{MINIO_PORT_9000_TCP_PORT},
});

builder {
    sub {
        my $env = shift;
        my $req = Plack::Request->new($env);

        my $path_info = $req->path_info;
        $path_info =~ s,^/,,;

        my $object = $s3->bucket("$ENV{BUCKET}")->get_key($path_info);
        return [ 404, [], [] ] unless $object;

        my @headers;
        push @headers, 'Content-Type'   => $object->{content_type};
        push @headers, 'Content-Length' => $object->{content_length};
        push @headers, Etag             => $object->{etag} if $object->{etag};
        return [ 200, \@headers, [$object->{value}] ];

    };
};



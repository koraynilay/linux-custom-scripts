#!/bin/perl
use strict;
use POSIX;
use JSON;
use Data::Dumper;

sub listenbrainz_json {
	# json;
	# ts;
	# duration;
	# media_player;
	# submission_client;

	my $song_tags = decode_json(@_[0]);
	#print Dumper($song_tags);

	my $recording_mbid = $song_tags->{MUSICBRAINZ_TRACKID};
	# check if the files has MusicBrainz tags;
	my $use_mb = $recording_mbid =~ /[a-z0-9-]{36}/;

	my %lb_json = (
		'listened_at' => int(@_[1]),
		'track_metadata' => {
			'additional_info' => {
				'artist_mbids' => [
					$song_tags->{MUSICBRAINZ_ARTISTID},
				],
				"duration_ms" => @_[2],
				"media_player" => @_[3],
				"recording_mbid" => $recording_mbid,
				"release_mbid" => $song_tags->{MUSICBRAINZ_ALBUMID},
				"submission_client" => @_[4],
				"track_mbid" => $song_tags->{MUSICBRAINZ_RELEASETRACKID},
				"tracknumber" => $song_tags->{Track},
			},
			"artist_name" => $song_tags->{Artist},
			"track_name" => $song_tags->{Title},
			"release_name" => $song_tags->{Album},
		},
	);

	my $lb_json_tm = $lb_json{track_metadata};
	my $lb_json_tm_ai = $lb_json_tm->{additional_info};

	if (!$use_mb) {
		delete $lb_json_tm_ai->{artist_mbids};

		delete $lb_json_tm_ai->{recording_mbid};
		delete $lb_json_tm_ai->{release_mbid};

		delete $lb_json_tm_ai->{track_mbid};
		delete $lb_json_tm_ai->{tracknumber};
	}

	if (!$lb_json_tm->{release_name}) {
		delete $lb_json_tm->{release_name};
	}

	#print Dumper(\%lb_json);

	exit 1 if !$lb_json_tm->{artist_name};
	exit 2 if !$lb_json_tm->{track_name};

	my $final_json = encode_json \%lb_json;
	print $final_json;
}

sub almost_listenbrainz_json {
	# json;
	# duration;
	# media_player;
	# submission_client;

	my $song_tags = decode_json(@_[0]);
	#print Dumper($song_tags);

	my $recording_mbid = $song_tags->{MUSICBRAINZ_TRACKID};
	# check if the files has MusicBrainz tags;
	my $use_mb = $recording_mbid =~ /[a-z0-9-]{36}/;

	my %lb_json = (
		'additional_info' => {
			'artist_mbids' => [
				$song_tags->{MUSICBRAINZ_ARTISTID},
			],
			"duration_ms" => @_[1],
			"media_player" => @_[2],
			"recording_mbid" => $recording_mbid,
			"release_mbid" => $song_tags->{MUSICBRAINZ_ALBUMID},
			"submission_client" => @_[3],
			"track_mbid" => $song_tags->{MUSICBRAINZ_RELEASETRACKID},
			"tracknumber" => $song_tags->{Track},
		},
		"artist_name" => $song_tags->{Artist},
		"track_name" => $song_tags->{Title},
		"release_name" => $song_tags->{Album},
	);

	my $lb_json_ai = $lb_json{additional_info};

	if (!$use_mb) {
		delete $lb_json_ai->{artist_mbids};

		delete $lb_json_ai->{recording_mbid};
		delete $lb_json_ai->{release_mbid};

		delete $lb_json_ai->{track_mbid};
		delete $lb_json_ai->{tracknumber};
	}

	if (!$lb_json{release_name}) {
		delete $lb_json{release_name};
	}

	#print Dumper(\%lb_json);

	exit 1 if !$lb_json{artist_name};
	exit 2 if !$lb_json{track_name};

	my $final_json = encode_json \%lb_json;
	print $final_json;
}

my %funcs = (
	lbj => \&listenbrainz_json,
	albj => \&almost_listenbrainz_json,
);
my $funcname = shift @ARGV;
$funcs{$funcname}(@ARGV);
exit 0;

#if ($use_mb) {
#	# json with MusicBrainz tags;
#	json="
#	{
#	  \"listened_at\": $listened_at,
#	  \"track_metadata\": {
#	    \"additional_info\": {
#	      \"artist_mbids\": [
#		\"$artist_mbid\"
#	      ],
#	      \"duration_ms\": $duration,
#	      \"media_player\": \"$media_player\",
#	      \"recording_mbid\": \"$recording_mbid\",
#	      \"release_mbid\": \"$release_mbid\",
#	      \"submission_client\": \"$submission_client\",
#	      \"track_mbid\": \"$track_mbid\",
#	      \"tracknumber\": \"$track_number\"
#	    },
#	    \"artist_name\": \"$artist\",
#	    \"track_name\": \"$title\"
#	    $(if [ -n "$album" ];then echo ,\"release_name\": \"$album\"; fi)
#	  }
#	}
#	";
#} else {
#	# json with MusicBrainz tags;
#	json="
#	{
#	  \"listened_at\": $listened_at,
#	  \"track_metadata\": {
#	    \"additional_info\": {
#	      \"duration_ms\": $duration,
#	      \"media_player\": \"$media_player\",
#	      \"submission_client\": \"$submission_client\"
#	    },
#	    \"artist_name\": \"$artist\",
#	    \"track_name\": \"$title\"
#	    $(if [ -n "$album" ];then echo ,\"release_name\": \"$album\";})
#	  }
#	}
#	";
#}

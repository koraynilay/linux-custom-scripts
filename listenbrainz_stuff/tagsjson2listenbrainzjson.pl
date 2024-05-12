#!/bin/perl
use strict;
use POSIX;
use JSON;
use Data::Dumper;

# json;
# ts;
# duration;
# media_player;
# submission_client;

my $song_tags = decode_json($ARGV[0]);
#print Dumper($song_tags);

my $recording_mbid = $song_tags->{MUSICBRAINZ_TRACKID};
# check if the files has MusicBrainz tags;
my $use_mb = $recording_mbid =~ /[a-z0-9-]{36}/;

my %lb_json = (
	'listened_at' => int($ARGV[1]),
	'track_metadata' => {
		'additional_info' => {
			'artist_mbids' => [
			],
			"duration_ms" => "",
			"media_player" => "",
			"recording_mbid" => "",
			"release_mbid" => "",
			"submission_client" => "",
			"track_mbid" => "",
			"tracknumber" => "",
		},
		"artist_name" => "",
		"track_name" => "",
		"release_name" => "",
	},	
);

my $lb_json_tm = $lb_json{track_metadata};
$lb_json_tm->{artist_name} = $song_tags->{Artist};
$lb_json_tm->{track_name} = $song_tags->{Title};
$lb_json_tm->{release_name} = $song_tags->{Album};

my $lb_json_tm_ai = $lb_json_tm->{additional_info};
$lb_json_tm_ai->{tracknumber} = $song_tags->{Track};
$lb_json_tm_ai->{duration_ms} = $ARGV[2];
$lb_json_tm_ai->{recording_mbid} = $recording_mbid;

$lb_json_tm_ai->{media_player} = $ARGV[3];
$lb_json_tm_ai->{submission_client} = $ARGV[4];

if ($use_mb) {
	#        $lb_json_tm_ai{artist_mbids} = $song_tags->{MUSICBRAINZ_ARTISTID};
	push @{$lb_json_tm_ai->{artist_mbids}}, $song_tags->{MUSICBRAINZ_ARTISTID};
	$lb_json_tm_ai->{release_mbid} = $song_tags->{MUSICBRAINZ_ALBUMID};
	$lb_json_tm_ai->{track_mbid} = $song_tags->{MUSICBRAINZ_RELEASETRACKID};
} else {
	delete $lb_json_tm_ai->{artist_mbids};

	delete $lb_json_tm_ai->{recording_mbid};
	delete $lb_json_tm_ai->{release_mbid};

	delete $lb_json_tm_ai->{track_mbid};
	delete $lb_json_tm_ai->{tracknumber};
}

if (!$lb_json_tm->{release_name}) {
	delete $lb_json_tm->{release_name};
}

my $final_json = encode_json \%lb_json;
print $final_json;
#print Dumper(\%lb_json);

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

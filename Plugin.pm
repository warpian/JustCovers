# 				Just Covers Squeezebox Server Plugin
#
#    Copyright (c) 2011 Tom Kalmijn (tkalmijn@yahoo.com)
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use strict;
use warnings;

package Plugins::JustCovers::Plugin;

use base qw(Slim::Plugin::Base);
use URI::Escape qw(uri_escape_utf8);
use HTML::Entities qw(encode_entities);
use Slim::Utils::Strings qw(string);
use Slim::Utils::Prefs;

my $serverPrefs = preferences('server');

my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.coversonly',
	'defaultLevel' => 'DEBUG',
	'description'  => 'PLUGIN_COVERSONLY',
});

my %allGenres; # cached genre info (id => genre) for use by albums.html

sub setMode { 
    my $client = shift; 
} 

sub getDisplayName { return string('PLUGIN_JUSTCOVERS'); }

sub initPlugin { 
    my $client = shift;
    $client->SUPER::initPlugin(@_);
    %allGenres = %{getGenres()}; 
}

# Prepares variables and processes the "genres.html" template.
sub showGenres {
    my ($client, $params) = @_;

    %allGenres = %{getGenres()}; # refresh cache with genre info used for breadcrum in albums.html.

    my @genres = sort {$a->{'name'} cmp $b->{'name'}} values %allGenres; # convert hash into array and sort by name
    push @{$params->{'genres'}}, @genres;

    # use global thumbnail setting to hitch hike on standard caching mechanism
    $params->{'size'} = $serverPrefs->get('thumbSize') || 100; 
    
    my $title = 'PLUGIN_JUSTCOVERS';
    $params->{'pagetitle'} = $title;
    $params->{'pageicon'} = $Slim::Web::Pages::additionalLinks{icons}{$title};
   
    # init bread crum navigation (actually a fixed hierarchical navigation)
    push @{$params->{'pwd_list'}}, {
		'title' => string($title),
		'href'  => 'href=genres.html?player=' . uri_escape_utf8($params->{'player'}),
    };
    # feed params to template
    return Slim::Web::HTTP::filltemplatefile('plugins/JustCovers/genres.html', $params);
}

# Prepares variables and processes the "albums.html" template.
sub showAlbums {
    my ($client, $params) = @_;
    
    my ($genreId) = $params->{'genre'};
    
    # assert valid genre id 
    if (!defined $genreId || !defined %allGenres->{$genreId}) { die "Cannot show albums: invalid genre id.\n" };

    my $genreName = %allGenres->{$genreId}->{'name'};        
    my $title = 'PLUGIN_JUSTCOVERS';

    $params->{'albums'} = getAlbumsByGenre($genreId);
    $params->{'size'} = $serverPrefs->get('thumbSize') || 100;;
    $params->{'pagetitle'} = $title;
    $params->{'pageicon'} = $Slim::Web::Pages::additionalLinks{icons}{$title};
    
    # bread crum navigation
    push @{$params->{'pwd_list'}}, {
		'title' => string($title),
		'href'  => 'href=genres.html?player=' . uri_escape_utf8($params->{'player'}),
    };
    push @{$params->{'pwd_list'}}, {
		'title' => $genreName,
		'href'  => 'href=albums.html?genre=' . $genreId . '&player=' .  uri_escape_utf8($params->{'player'}),
    };    
    # feed above params to template
    return Slim::Web::HTTP::filltemplatefile('plugins/JustCovers/albums.html', $params);
}

# Returns a hash with all the genres, including a more or less randomly 
# picked cover art (from a track associated with the genre).
#
# TODO: make some provision for missing album art. Let the user pick album
# art for each genre in a settings page? Note: we cannot trust the cover id
# over time -> must rely on track meta data then (feels shaky).
#
sub getGenres {
    my %genres; 

    my $sql = <<EOT;
SELECT
    genres.name, genres.id, tracks.coverid
FROM  
    genres
JOIN 
    genre_track ON genre_track.genre = genres.id
JOIN
    tracks ON tracks.id = genre_track.track
GROUP BY
    genres.name
EOT

    my $dbh = Slim::Schema->dbh;
    my $sth = $dbh->prepare_cached($sql);
    $sth->execute;

    # fetch row by row to preserve order and do some decoding
    while (my $genre = $sth->fetchrow_hashref()) {
        utf8::decode($genre->{'name'});
        %genres->{$genre->{'id'}} = $genre;
    }    
    $sth->finish;

    return \%genres;
}

# Returns an array with all the albums which belong to the specified genre.
#
# The order of the array is a stable sort on: artist, year and ablum title. 
# TODO: make customizable (hitch hike on general sorting options)?
#
sub getAlbumsByGenre {
    my $genreId = shift;    
    my @albums = ();    
    my $collate = Slim::Utils::OSDetect->getOS()->sqlHelperClass()->collate();
    
    my $sql = <<EOT;
SELECT 
    album.id, album.title, album.artwork coverid, album.year, artist.name artist 
FROM
    albums album 
JOIN
    contributors artist ON artist.id = album.contributor
WHERE
    album.id IN (
        SELECT DISTINCT
            tracks.album
        FROM 
            genre_track 
        JOIN
            tracks ON tracks.id = genre_track.track
        WHERE 
            genre_track.genre = $genreId
        )
ORDER BY 
     artist.namesort $collate, album.year, album.titlesort $collate      
EOT

    my $dbh = Slim::Schema->dbh;
    my $sth = $dbh->prepare_cached($sql);
    $sth->execute;			

    # fetch row by row to preserve ORDER BY and do some decoding
    while (my $album = $sth->fetchrow_hashref()) {
        utf8::decode($album->{'title'});
        utf8::decode($album->{'artist'});
        push @albums, $album;
    }    
    $sth->finish;
    
    return \@albums;
}

# Sets general hooks to let the Plugin live in the SB server environment.
sub webPages { 
    Slim::Web::Pages->addPageFunction('JustCovers/genres.html', \&showGenres);
    Slim::Web::Pages->addPageFunction('JustCovers/albums.html', \&showAlbums);
    
    Slim::Web::Pages->addPageLinks("browse", { 'PLUGIN_JUSTCOVERS' => 'plugins/JustCovers/genres.html' });
    Slim::Web::Pages->addPageLinks("icons", { 'PLUGIN_JUSTCOVERS' => 'plugins/JustCovers/html/images/justcovers.png' });
}

1;

__END__

#    main::DEBUGLOG && $log->is_debug && $log->debug("executing sql: " . $sql);
    


# 				Just Covers Squeezebox Server Plugin
#
#    Copyright (c) 2011 Tom Kalmijn (tkalmijn@gmail.com)
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

package Plugins::JustCovers::Settings;

use strict;
use warnings;

use base qw(Slim::Web::Settings);

use Slim::Utils::Prefs;
use Slim::Utils::Log;
use Slim::Utils::PluginManager;

my $prefs = preferences('plugin.justcovers');
my $serverPrefs = preferences('server');
my $log = logger('plugin.justcovers');

sub name {
	return Slim::Web::HTTP::CSRF->protectName('PLUGIN_JUSTCOVERS');
}

sub page {
	return Slim::Web::HTTP::CSRF->protectURI('plugins/JustCovers/settings/basic.html');
}

sub prefs {
	return ($prefs, qw(showAlbumText showShadows extraPadding clickAlbumAction));
}

sub handler {
	my ($class, $client, $params) = @_;

	if ($params->{'saveSettings'}) {

        $params->{'pref_showShadows'} = defined $params->{'pref_showShadows'} ? 'on' : 'off';

        $params->{'pref_showAlbumText'} = defined $params->{'pref_showAlbumText'} ? 'on' : 'off';
        if ($params->{'pref_showAlbumText'} eq 'on') {
            $serverPrefs->set('showArtist', $params->{'pref_showArtist'});
            $serverPrefs->set('showYear', $params->{'pref_showYear'});
        }
        $serverPrefs->set('thumbSize', $params->{'pref_thumbSize'});
        $serverPrefs->set('itemsPerPage', $params->{'pref_itemsPerPage'});
    }

	if ($params->{'reset'}) {
        $params->{'showAlbumText'} = 'on';
        $params->{'showShadows'} = 'off';
        $params->{'extraPadding'} = 10;
        $params->{'clickAlbumAction'} = 'play';
    }

    $params->{'jcversion'} = Slim::Utils::PluginManager->allPlugins->{'JustCovers'}->{'version'};
    return $class->SUPER::handler($client, $params);
}

1;

__END__


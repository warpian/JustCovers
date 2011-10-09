package Plugins::JustCovers::Settings;

use strict;
use warnings;

use base qw(Slim::Web::Settings);

use Slim::Utils::Prefs;
use Slim::Utils::Log;

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
    }

    return $class->SUPER::handler($client, $params);
}

1;

__END__


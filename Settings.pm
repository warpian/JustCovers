package Plugins::JustCovers::Settings;

use strict;
use warnings;

use base qw(Slim::Web::Settings);

use Slim::Utils::Prefs;
use Slim::Utils::Log;

my $prefs = preferences('plugin.justcovers');
my $log = logger('plugin.justcovers');

sub name {
	return Slim::Web::HTTP::CSRF->protectName('PLUGIN_JUSTCOVERS');
}

sub page {
	return Slim::Web::HTTP::CSRF->protectURI('plugins/JustCovers/settings/basic.html');
}

sub prefs {
	return ($prefs, qw(showAlbumTitle showShadows));
}

sub handler {
	my ($class, $client, $params) = @_;

	if ($params->{'saveSettings'}) {

        $params->{'pref_showAlbumTitle'} = defined $params->{'pref_showAlbumTitle'} ? 'on' : 'off';
        $params->{'pref_showShadows'} = defined $params->{'pref_showShadows'} ? 'on' : 'off';
    }

	if ($params->{'reset'}) {
        $params->{'showAlbumTitle'} = 'on';
        $params->{'showShadows'} = 'off';
    }

    return $class->SUPER::handler($client, $params);
}

1;

__END__


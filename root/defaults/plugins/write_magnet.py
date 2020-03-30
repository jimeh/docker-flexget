import os
import time

from loguru import logger

from flexget import plugin
from flexget.event import event
from flexget.utils.pathscrub import pathscrub
from flexget.utils.tools import parse_timedelta

logger = logger.bind(name='write_magnet')


class ConvertMagnet:
    """Convert magnet only entries to a torrent file"""

    schema = {
        "oneOf": [
            # Allow write_magnet: no form to turn off plugin altogether
            {"type": "boolean"},
            {
                "type": "object",
                "properties": {
                    "timeout": {"type": "string", "format": "interval"},
                    "force": {"type": "boolean"},
                    "num_try": {"type": "integer"},
                },
                "additionalProperties": False,
            },
        ]
    }

    def __init__(self):
        try:
            import requests
            trackers_url_from = 'https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best_ip.txt'
            self.trackers = requests.get(trackers_url_from).content.decode('utf8').split('\n\n')[:-1]
        except Exception as e:
            logger.debug('Failed to get tracker list: {}', str(e))
            self.trackers = []

    def magnet_to_torrent(self, magnet_uri, destination_folder, timeout, num_try):
        import libtorrent

        # parameters
        params = libtorrent.parse_magnet_uri(magnet_uri)

        # prevent downloading
        # https://stackoverflow.com/q/45680113
        params.flags |= libtorrent.add_torrent_params_flags_t.flag_upload_mode
        
        lt_version = [int(v) for v in libtorrent.version.split('.')]
        if [0, 16, 13, 0] < lt_version < [1, 1, 3, 0]:
            # for some reason the info_hash needs to be bytes but it's a struct called sha1_hash
            params.info_hash = params.info_hash.to_bytes()

        # add_trackers
        if len(params.trackers) == 0:
            try:
                import random
                params.trackers = random.sample(self.trackers, 5)
            except Exception as e:
                logger.debug('Failed to add trackers: {}', str(e))
        
        # session
        session = libtorrent.session()

        session.listen_on(6881, 6891)
        
        session.add_extension('ut_metadata')
        session.add_extension('ut_pex')
        session.add_extension('metadata_transfer')

        session.add_dht_router('router.utorrent.com', 6881)
        session.add_dht_router('router.bittorrent.com', 6881)
        session.add_dht_router("dht.transmissionbt.com", 6881)
        session.add_dht_router('127.0.0.1', 6881)
        session.start_dht()

        # handle
        handle = session.add_torrent(params)
        handle.force_dht_announce()
        logger.debug('Acquiring torrent metadata for magnet {}', magnet_uri)
        
        for tryid in range(max(num_try,1)):
            timeout_value = timeout
            while not handle.has_metadata():
                time.sleep(0.1)
                timeout_value -= 0.1
                if timeout_value <= 0:
                    logger.debug('Failed to get metadata on trial: {}/{}'.format(tryid+1, num_try))
                    break

            if handle.has_metadata():
                logger.debug('Metadata acquired after {} seconds on trial {}'.format(timeout - timeout_value, tryid+1))
                break
            else:
                if tryid+1 == max(num_try,1):
                    session.remove_torrent(handle, True)
                    raise plugin.PluginError(
                        'Timed out after {}x{} seconds trying to magnetize'.format(timeout, num_try)
                    )
    
        torrent_info = handle.get_torrent_info()
        torrent_file = libtorrent.create_torrent(torrent_info)
        torrent_path = pathscrub(
            os.path.join(destination_folder, torrent_info.name() + ".torrent")
        )
        with open(torrent_path, "wb") as f:
            f.write(libtorrent.bencode(torrent_file.generate()))
        logger.debug('Torrent file wrote to {}', torrent_path)
        return torrent_path

    def prepare_config(self, config):
        if not isinstance(config, dict):
            config = {}
        config.setdefault('timeout', '10 seconds')
        config.setdefault('force', False)
        config.setdefault('num_retry', 3)
        return config

    @plugin.priority(plugin.PRIORITY_FIRST)
    def on_task_start(self, task, config):
        if config is False:
            return
        try:
            import libtorrent  # noqa
        except ImportError:
            raise plugin.DependencyError(
                'write_magnet', 'libtorrent', 'libtorrent package required', logger
            )

    @plugin.priority(130)
    def on_task_download(self, task, config):
        if config is False:
            return
        config = self.prepare_config(config)
        # Create the conversion target directory
        converted_path = os.path.join(task.manager.config_base, 'converted')

        timeout = parse_timedelta(config['timeout']).total_seconds()

        if not os.path.isdir(converted_path):
            os.mkdir(converted_path)

        for entry in task.accepted:
            if entry['url'].startswith('magnet:'):
                entry.setdefault('urls', [entry['url']])
                try:
                    logger.info('Converting entry {} magnet URI to a torrent file', entry['title'])
                    torrent_file = self.magnet_to_torrent(entry['url'], converted_path, timeout, config['num_try'])
                except (plugin.PluginError, TypeError) as e:
                    logger.error(
                        'Unable to convert Magnet URI for entry {}: {}', entry['title'], e
                    )
                    if config['force']:
                        entry.fail('Magnet URI conversion failed')
                    continue
                # Windows paths need an extra / prepended to them for url
                if not torrent_file.startswith('/'):
                    torrent_file = '/' + torrent_file
                entry['url'] = torrent_file
                entry['file'] = torrent_file
                # make sure it's first in the list because of how download plugin works
                entry['urls'].insert(0, 'file://{}'.format(torrent_file))


@event('plugin.register')
def register_plugin():
    plugin.register(ConvertMagnet, 'write_magnet', api_ver=2)

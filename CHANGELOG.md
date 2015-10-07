## v0.4.2
* Make modification of chef-server embedded runit cookbook more robust
* Backport miasma-powered backup script from 1.0 trunk to avoid being trolled by fog installation process

## v0.4.0
* Allow for creation of clients, users, or both
* Store backup configuration in separate JSON file
* Provide proper retries to account for temporary server unavailability
* Include full server restart on restore from backup
* Provide 'latest' backup files along with named files
* Convert backup script from template to cookbook file
* Make service restarts more consistent

## v0.3.2
* Add client creation retries to stabilize initial bootstrap
* Updates to example bootstrap script
* Add support for backup/restore (thanks @luckymike!)

## v0.3.0
* Include chef-server dependency
* Update configuration overrides for chef-server
* Use `:endpoint` attribute for custom hostname/ip

## v0.2.0
* Provide distinct solo vs. client recipes
* Client recipe configures dna.json and uses ctl for reconfigure

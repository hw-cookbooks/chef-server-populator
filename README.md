## Chef Server Populator

Creates admin clients and installs provided public key. Simplifies managing and
recreating erchef nodes. Provides backup and restore recipes for
complete erchef recovery.

### Usage

When bootstrapping with the chef-server cookbook and chef-solo:

* Download and unpack chef-server and chef-server-populator cookbooks
* Upload public keys to be used by clients
* Create json to add client and key information
* Run chef-solo

When converging with chef-client:

* Create data bag to hold data bag item with client information
* Create data bag item with client information
* Set data bag related attributes

Applicable attributes:

* `node[:chef_server_populator][:databag]` - name of the data bag

Structure of the data bag item:

```json
{
  "id": "client_name",
  "chef_server": {
    "client_key": "public key contents",
    "type": [
      "user",
      "client"
    ],
    "enabled": true,
    "admin": true
  }
}
```

Restoring from a backup:

* Set path to restore file with node[:chef_server_populator][:restore][:file]
* The restore recipe is run if a restore file is set
* The restore file can be remote or local

When enabling backups:

* Include chef-server-populator::restore recipe
* Set backup cron interval with node[:chef_server_populator][:schedule]
* Optionally set a remote storage location with node[:chef_server_populator][:backup][:remote][:connection]
* Backups include both a pg_dump of the entire chef database and a tarball of the bookshelf data directory

## Extras

Need to use the IP address of the node for a bit, or another name  instead of
having `node[:fqdn]`?

* `node[:chef_server_populator][:servername_override]`

Keep chef server configured via chef client:

* `node[:chef_server_populator][:chef_server]`

If the hash is non-empty, it will write the chef-server `dna.json` and trigger a
`reconfigure` when ever the attributes are updated.

## Examples

Take a look in the `examples` directory for basic bootstrap templates that will
build a new erchef server, using existing keys and client, and
register itself, or restore an existing chef server from a backup.

## Info
* Repository: https://github.com/hw-cookbooks/chef-server-populator
* IRC: Freenode @ #heavywater

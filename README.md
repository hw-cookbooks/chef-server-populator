## Chef Server Populator

Creates admin clients and installs provided public key. Simplifies managing and
recreating erchef nodes.

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
* `node[:chef_server_populator][:databag_item]` - name of the data bag item

Structure of the data bag item:

```json
{
  "id": "my_clients",
  "clients": {
    "client_x": "public key contents",
    "client_y": "public key contents"
  }
}
```

## Extras

Need to use the IP address of the node for a bit, or another name  instead of 
having `node[:fqdn]`?

* `node[:chef_server_populator][:servername_override]`

Want the actual chef-server cookbook for configuring chef-server installed so
the chef-server can manage itself? Just flip the switch:

* `node[:chef_server_populator][:install_chef_server_cookbooks]`

## Examples

Take a look in the `examples` directory for a basic bootstrap template that will
build a new erchef server, using existing keys and client, and register itself.

## Info
* Repository: https://github.com/hw-cookbooks/chef-server-populator
* IRC: Freenode @ #heavywater

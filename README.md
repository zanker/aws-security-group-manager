Overview
===
This is a solution to managing AWS security groups across multiple regions, where you want to only allow certain groups of servers, without having to manually deal with the ips.

You setup a configuration file of how you want it to work, as well as the security groups or ips that can have access to it. Depending on the configuration, you can do things like "Add the IP for every server in the foo security group on all regions to the bar security group, except for us-west-1, just add the actual foo group."

AWS has limits on how many rules can be in a single security group (100 on EC2, 50 on VPS). Amazon also recommends you don't have too many rules in a security group as EC2 instances can have multiple security groups.

Keep that in mind if you're using this tool, it's mostly intended as a way of keeping a small scale cross region deployment secure and to bridge the gap before having to deal with large scale locking down of EC2 security groups across regions.

With that out of the way:

Examples
-

See `aws-security-groups --help` for a list of commands, an example configuration file can be found at https://gist.github.com/3231660.

Quick syntax notes:

`group` can either be the specific name of the group (`foobar`) or `:ALL` to indicate all servers
`region` you can filter it to only add servers from a specific group by a single region (`us-west-1`), servers from the same region as the security group with `:SAME`, or servers from all regions with `:ALL`
`ip` can be the IP range to allow access too, `0.0.0.0/0` will give everyone access
`protocol` can either be `tcp` or `udp`
`port` can either be a single port (`4000`) or a range (`3000-4000`)
`note` doesn't do anything, just gives you a text note of what the rule is for

You can either specify `group` or `ip` per rule, but not both.

Hypothetically, if you have a server setup like so:

mem1 in us-west-1 and mem2 in us-east-1 (part of the memcached and default group)
app1 in us-west-1 and app2 in us-east-1 (part of the app and default group)
mongo1 in us-west-1 and mongo2 in us-east-1 (part of the mongo and default group)
mongo-backup in us-west-2 (part of the mongo-backup and default group)
monitor in us-west-2 (part of the monitor group)
puppetmaster in us-west-2 (part of the puppetmaster group)
rds server in us-east-1 (part of app-database)

Using the example configuration file, it will generate a security group of:

*us-east-1*
`memcached` - app group can access it by port 11211 using TCP
`mongo` - app group, app servers on us-west-1 with the IP 22.33.44.55, mongo-backup on us-west-2 with the IP 77.77.88.99, other servers in the mongo group, and the mongo server in us-west-1 with the IP 55.11.22.33 can access servers in the mongo group
`default` - anyone can SSH in. the monitor server with IP 50.50.50.50 can access servers by TCP on ports 4949 and 4313
`app-database` (rds) - app group, app servers on us-west-1 with the IP 22.33.44.55 can access the RDS server

*us-west-1*
`memcached` - app group can access it by port 11211 using TCP
`mongo` - app group, app servers on us-east-1 with the IP 88.33.99.22, mongo-backup on us-west-2 with the IP 77.77.88.99, other servers in the mongo group, and the mongo server in us-east-1 with the IP 11.88.33.99 can access servers in the mongo group
`default` - anyone can SSH in. the monitor server with IP 50.50.50.50 can access servers by TCP on ports 4949 and 4313

*us-west-2*
`monitor` - no rules handled as it's not specified in the config file
`puppetmaster` - The IPs of all the servers in us-west-1 and us-east-1 are able to access TCP over port 8100, and any servers part of the monitor, mongo-backup or puppetmaster group are able to access it over TCP on port 8100 as well.

If a security group is not listed in the configuration file, it will not be touched.
This will not make destructive changes to your security groups, if a rule already exists in a security group, but not in the one from the config file, it will leave it alone unless you specify `--destructive`

Confirmation is asked before making any changes, use `--noop` to not make any changes, or `--assumeyes` and it won't ask for confirmation before changing things.

License
-
Available under the MIT license
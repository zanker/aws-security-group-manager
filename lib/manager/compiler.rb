module AWSSecurityGroups
  class Compiler
    def initialize(security_groups, servers)
      @security_groups, @servers = security_groups, servers
    end

    def build(product, region, group_name, group_config)
      unless product == "ec2" or product == "rds"
        raise "Unknown or unsupported AWS product #{product}"
      end

      compiled = []

      group_config.each do |config|
        if product == "ec2"
          next unless config["protocol"] and config["port"]
        end

        # We're configuring a group to have access
        if config["group"]
          groups, ips = self.find_servers(region, config)
          groups.each do |group|
            compiled.push(:group => group)
          end

        # We're configuring an IP range to have access
        elsif config["ip"]
          ips = [config["ip"]]
        end

        ips.each do |ip|
          compiled.push(:ip => ip, :port => config["port"], :protocol => config["protocol"])
        end
      end

      compiled
    end

    # Find servers and groups matching the ruleset given
    def find_servers(region, config)
      groups, ips = [], []

      @servers.each do |server_region, list|
        # Only add servers that are part of the security group in the same region as this security group
        if config["region"] == :SAME and region != server_region
          next
        end

        # Only add servers that are part of the security group in a specific region
        if config["region"].is_a?(String) and config["region"] != server_region
          next
        end

        list.each do |instance_id, instance|
          # We're filtering by a specific group
          if config["group"].is_a?(String) and !instance[:group_names].include?(config["group"])
            next
          end

          # Same region, so add the security group to itself
          if server_region == region
            if config["group"] == :ALL
              instance[:group_names].each do |group|
                groups.push(group)
              end
            else
              groups.push(config["group"])
            end

          # Different region, authorize the IP
          else
            ips.push("#{instance[:ip_address]}/32")
          end
        end
      end

      groups.uniq!
      return groups, ips
    end
  end
end
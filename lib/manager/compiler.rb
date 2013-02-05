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
      added_groups = {}

      group_config.each do |config|
        if product == "ec2"
          next unless config["protocol"] and config["port"]

          if config["port"].is_a?(String)
            from_port, to_port = config["port"].split("-", 2)
          else
            from_port = config["port"]
          end

          to_port ||= from_port
        end

        # We're configuring a group to have access
        if config["group"]
          groups, ips = self.find_servers(region, config)
          groups.each do |group|
            added_groups["#{group}#{config["protocol"]}#{from_port}#{to_port}"] = {:group => group, :protocol => config["protocol"], :from_port => from_port, :to_port => to_port}
          end

        # We're configuring an IP range to have access
        elsif config["ip"]
          ips = [config["ip"]]
        end

        ips.each do |ip|
          compiled.push(:ip => ip, :from_port => from_port, :to_port => to_port, :protocol => config["protocol"])
        end
      end

      compiled.concat(added_groups.values)

      compiled
    end

    # Find servers and groups matching the ruleset given
    def find_servers(region, config)
      groups, ips = [], []
      
      if config["region"] == :SAME
        return [config["group"]], ips
      end
      
      @servers.each do |server_region, list|
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

      return groups, ips
    end
  end
end
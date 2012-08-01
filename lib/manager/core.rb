require "fog"
require "yaml"

module AWSSecurityGroups
  class Core
    def initialize(access_key, secret_key)
      @access_key, @secret_key = access_key, secret_key
    end

    def load_regions
      aws = Fog::Compute.new(:provider => "AWS", :region => "us-east-1", :aws_access_key_id => @access_key, :aws_secret_access_key => @secret_key)
      @regions = aws.describe_regions.body["regionInfo"].map {|r| r["regionName"]}
    end

    def load_security_groups
      @security_groups = {}
      @regions.each do |region|
        @security_groups[region] = {}

        aws = Fog::Compute.new(:provider => "AWS", :region => region, :aws_access_key_id => @access_key, :aws_secret_access_key => @secret_key)
        aws.security_groups.each do |group|
          @security_groups[region][group.group_id] = {:name => group.name, :owner_id => group.owner_id, :permissions => group.ip_permissions}
        end

        @security_groups.delete(region) if @security_groups[region].empty?
      end
    end

    def load_servers
      @servers = {}
      @security_groups.each_key do |region|
        @servers[region] = {}

        aws = Fog::Compute.new(:provider => "AWS", :region => region, :aws_access_key_id => @access_key, :aws_secret_access_key => @secret_key)
        aws.describe_instances("instance-state-name" => "running").body["reservationSet"].each do |instance|
          instance_set = instance["instancesSet"].first
          @servers[region][instance_set["instanceId"]] = {:group_names => instance_set["groupSet"], :group_ids => instance_set["groupIds"], :ip_address => instance_set["ipAddress"]}
        end

        # Assuming if you don't have any servers in the region, you don't care about it
        if @servers[region].empty?
          @servers.delete(region)
          @security_groups.delete(region)
        end
      end
    end

    def build_security_groups(product, config)
      compiler = Compiler.new(@security_groups, @servers)

      new_groups = {}
      config.each do |group_name, group|
        new_groups[group_name] = compiler.build(product, group_name, group)
      end

      new_groups
    end
  end
end
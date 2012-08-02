require "fog"
require "yaml"

module AWSSecurityGroups
  attr_reader :servers

  class Core
    def initialize(access_key, secret_key)
      @access_key, @secret_key = access_key, secret_key
    end

    def load_regions
      aws = Fog::Compute.new(:provider => "AWS", :region => "us-east-1", :aws_access_key_id => @access_key, :aws_secret_access_key => @secret_key)
      @regions = aws.describe_regions.body["regionInfo"].map {|r| r["regionName"]}
    end

    def load_security_groups
      @security_groups = {"ec2" => {}, "rds" => {}}

      # EC2
      @regions.each do |region|
        @security_groups["ec2"][region] = {}

        aws = Fog::Compute.new(:provider => "AWS", :region => region, :aws_access_key_id => @access_key, :aws_secret_access_key => @secret_key)
        aws.security_groups.each do |group|
          @security_groups["ec2"][region][group.name] = {:group_id => group.group_id, :owner_id => group.owner_id, :permissions => group.ip_permissions}
        end

        @security_groups["ec2"].delete(region) if @security_groups["ec2"][region].empty?
      end

      # RDS
      @regions.each do |region|
        @security_groups["rds"][region] = {}

        rds = Fog::AWS::RDS.new(:region => region, :aws_access_key_id => @access_key, :aws_secret_access_key => @secret_key)
        rds.describe_db_security_groups.body["DescribeDBSecurityGroupsResult"]["DBSecurityGroups"].each do |group|
          @security_groups["rds"][region][group["DBSecurityGroupName"]] = {:owner_id => group["OwnerId"], :ec2 => group["EC2SecurityGroups"], :ip => group["IPRanges"]}
        end
      end
    end

    def load_servers
      @servers = {"ec2" => {}, "rds" => {}}

      # Load a list of EC2 servers
      @regions.each do |region|
        @servers["ec2"][region] = {}

        aws = Fog::Compute.new(:provider => "AWS", :region => region, :aws_access_key_id => @access_key, :aws_secret_access_key => @secret_key)
        aws.describe_instances("instance-state-name" => "running").body["reservationSet"].each do |instance|
          instance_set = instance["instancesSet"].first
          @servers["ec2"][region][instance_set["instanceId"]] = {:group_names => instance["groupSet"], :group_ids => instance["groupIds"], :ip_address => instance_set["ipAddress"]}
        end

        @servers["ec2"].delete(region) if @servers["ec2"][region].empty?
      end

      # Now RDS
      @regions.each do |region|
        @servers["rds"][region] = {}

        rds = Fog::AWS::RDS.new(:region => region, :aws_access_key_id => @access_key, :aws_secret_access_key => @secret_key)
        rds.describe_db_instances.body["DescribeDBInstancesResult"]["DBInstances"].each do |instance|
          group_names = []
          instance["DBSecurityGroups"].each do |group|
            group_names.push(group["DBSecurityGroupName"]) if group["Status"] == "active"
          end

          @servers["rds"][region][instance["DBInstanceIdentifier"]] = {:group_names => group_names}
        end

        @servers["rds"].delete(region) if @servers["rds"][region].empty?
      end
    end

    def compile_security_groups(product, settings)
      compiler = Compiler.new(@security_groups[product], @servers["ec2"])

      new_groups = {}
      settings.each do |group_name, group_config|
        new_groups[group_name] = {}

        @regions.each do |region|
          # Don't set security groups if the region has no servers
          # Or if the region doesn't actually have the security group, that would be pointless
          unless @servers[product][region] and @security_groups[product][region] and @security_groups[product][region][group_name]
            next
          end

          new_groups[group_name][region] = compiler.build(product, region, group_name, group_config)
        end
      end

      new_groups
    end
  end
end
module AWSSecurityGroups
  class Updater
    def initialize(args)
      @product, @region, @owner_id = args[:product], args[:region], args[:owner_id]

      if @product == "ec2"
        @aws = Fog::Compute.new(:provider => "AWS", :region => @region, :aws_access_key_id => args[:access_key], :aws_secret_access_key => args[:secret_key])
      elsif @product == "rds"
        @aws = Fog::AWS::RDS.new(:region => @region, :aws_access_key_id => args[:access_key], :aws_secret_access_key => args[:secret_key])
      end
    end

    def add_rules(group_name, rules)
      self.send("add_#{@product}_rules", group_name, rules)
    end

    def remove_rules(group_name, rules)
      self.send("remove_#{@product}_rules", group_name, rules)
    end

    private
    # EC2
    def format_ec2_rule(rule)
      if rule[:ip]
        data = {"IpRanges" => [{"CidrIp" => rule[:ip]}]}
      else
        data = {"Groups" => [{"GroupName" => rule[:group], "UserId" => @owner_id}]}
      end

      {"IpPermissions" => [data.merge("IpProtocol" => rule[:protocol], "FromPort" => rule[:from_port].to_i, "ToPort" => rule[:to_port].to_i)]}
    end

    def add_ec2_rules(group_name, rules)
      rules.each do |rule|
        data = format_ec2_rule(rule)

        puts "AUTHORIZE: #{data}"
        @aws.authorize_security_group_ingress(group_name, data)
      end
    end

    def remove_ec2_rules(group_name, rules)
      rules.each do |rule|
        data = format_ec2_rule(rule)

        puts "REVOKING: #{data}"
        @aws.revoke_security_group_ingress(group_name, data)
      end
    end

    # RDS
    def add_rds_rules(group_name, rules)
      rules.each do |rule|
        if rule[:ip]
          data = {"CIDRIP" => rule[:ip]}
        else
          data = {"EC2SecurityGroupName" => rule[:group], "EC2SecurityGroupOwnerId" => @owner_id}
        end

        puts "AUTHORIZE: #{data}"
        @aws.authorize_db_security_group_ingress_ingress(group_name, {"CIDRIP" => rule[:ip]})
      end
    end

    def remove_rds_rules(group_name, rules)
      rules.each do |rule|
        if rule[:ip]
          data = {"CIDRIP" => rule[:ip]}
        else
          data = {"EC2SecurityGroupName" => rule[:group], "EC2SecurityGroupOwnerId" => @owner_id}
        end

        puts "REVOKING: #{data}"
        @aws.revoke_db_security_group_ingress(group_name, data)
      end
    end
  end
end
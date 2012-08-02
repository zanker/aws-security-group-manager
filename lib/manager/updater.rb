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
    def format_for_aws(rules)
      rules.map do |rule|
        if rule[:ip]
          {"IpRanges" => [{"CidrIp" => rule[:ip]}], "IpProtocol" => rule[:protocol], "FromPort" => rule[:port], "ToPort" => rule[:port]}
        else
          {"Groups" => [{"GroupName" => rule[:group], "UserId" => @owner_id}]}
        end
      end
    end

    def add_ec2_rules(group_name, rules)
      data = {"IpPermissions" => format_for_aws(rules)}

      puts "AUTHORIZE: #{data}"
      @aws.authorize_security_group_ingress(group_name, data)
    end

    def remove_ec2_rules(group_name, rules)
      data = {"IpPermissions" => format_for_aws(rules)}

      puts "REVOKING: #{data}"
      @aws.revoke_security_group_ingress(group_name, data)
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
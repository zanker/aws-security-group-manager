module AWSSecurityGroups
  class Compiler
    def initialize(groups, servers)
      @groups, @servers = groups, servers
    end

    def build(product, group_name, config)
      if product == :ec2
        build_ec2(group_name, config)
      elsif product == :rds
        build_rds(group_name, config)
      else
        raise "Unknown or unsupported AWS product #{product}"
      end
    end

    private
    def build_ec2(group_name, config)

    end

    def build_rds(group_name, config)
      
    end
  end
end
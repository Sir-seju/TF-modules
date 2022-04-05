##########################################
###### Resource for Elastic Beanstalk App
##########################################

resource "aws_elastic_beanstalk_application" "app" {
  name        = var.Application_name
  description = "Application name of the Elastic Beanstalk"
}

resource "aws_elastic_beanstalk_environment" "default"{
    name                    =  var.environment_name
    application             = aws_elastic_beanstalk_application.app.name
    application             = var.Application_name
    tier                    = var.tier
    cname_prefix            = var.environment_url
    version_label           = var.version_label
    description              = "Elastic Beanstalk application for ${var.Application_name} in ${var.environment} environment"
    solution_stack_name     = var.solution_stack_name
    wait_for_ready_timeout  = var.wait_for_ready_timeout
    tags = var.tags    
    
    setting {
        namespace   = "aws:elasticbeanstalk:environment:proxy"
        name        = "ProxyServer"
        value       = var.proxy_server
    } 
    setting {
        namespace   = "aws:autoscaling:launchconfiguration"
        name        = "IamInstanceProfile"
        value       = var.instance_profile_role
    }
    setting {
        namespace   = "aws:autoscaling:launchconfiguration"
        name        = "SecurityGroups"
        value       = join(",", sort(var.security_groups))
    }
    setting {
        namespace   = "aws:autoscaling:launchconfiguration"
        name        = "EC2KeyName"
        value       = var.aws_key_pair
    }
    setting {
        namespace   = "aws:ec2:vpc"
        name        = "VPCId"
        value       = var.vpc_id
    }
    setting {
        namespace   = "aws:ec2:vpc"
        name        = "AssociatePublicIpAddress"
        value       = var.associate_public_ip_address
    }
    setting {
        namespace   = "aws:ec2:vpc"
        name        = "Subnets"
        value       = join(",", sort(var.application_subnets))
    }
    setting {
        namespace   = "aws:ec2:vpc"
        name        = "ELBSubnets"
        value       = join(",", sort(var.loadbalancer_subnets))
    }
    setting {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "LoadBalancerType"
      value     = var.loadbalancer_type
    }
    setting {
        namespace   = "aws:ec2:vpc"
        name        = "ELBScheme"
        value       = var.environment_type == "LoadBalanced" ? var.elb_scheme : ""
    }
    setting {
        namespace = "aws:elasticbeanstalk:environment"
        name      = "EnvironmentType"
        value     = var.environment_type
    }
    setting {
        namespace   = "aws:autoscaling:launchconfiguration"
        name        = "InstanceType"
        value       = var.instance_type
    }
    setting {
        namespace   = "aws:autoscaling:launchconfiguration"
        name        = "RootVolumeSize"
        value       = var.root_volume_size
    }
    setting {
        namespace   = "aws:autoscaling:launchconfiguration"
        name        = "RootVolumeType"
        value       = var.root_volume_type
    }
    setting {
        namespace   = "aws:autoscaling:asg"
        name        = "Availability Zones"
        value       = var.availability_zone
    }
    setting {
        namespace   = "aws:autoscaling:asg"
        name        = "MinSize"
        value       = var.autoscale_min
    }
    setting {
        namespace   = "aws:autoscaling:asg"
        name        = "MaxSize"
        value       = var.autoscale_max
    }
    setting {
        namespace   = "aws:elasticbeanstalk:environment"
        name        = "ServiceRole"
        value       = var.service_role
    }
    setting {
        namespace   = "aws:elasticbeanstalk:application:environment"
        name        = "environment"
        value       = var.environment
    }
    setting {
        namespace   = "aws:elasticbeanstalk:healthreporting:system"
        name        = "SystemType"
        value       = var.enhanced_reporting_enabled ? "enhanced" : "basic"
    }
    setting {
        namespace   = "aws:autoscaling:updatepolicy:rollingupdate"
        name        = "RollingUpdateEnabled"
        value       = var.rolling_update_enabled
    }
    setting {
        namespace   = "aws:autoscaling:updatepolicy:rollingupdate"
        name        = "RollingUpdateType"
        value       = var.rolling_update_type
    }
    setting {
        namespace   = "aws:autoscaling:updatepolicy:rollingupdate"
        name        = "MinInstancesInService"
        value       = var.MinInstancesInService
    }
    setting {
        namespace   = "aws:autoscaling:updatepolicy:rollingupdate"
        name        = "MaxBatchSize"
        value       = "1"
    }
    setting {
        namespace   = "aws:elb:loadbalancer"
        name        = "CrossZone"
        value       = var.loadbalancer_crosszone
    }
    setting {
        namespace   = "aws:elasticbeanstalk:command"
        name        = "BatchSizeType"
        value       = var.BatchSizeType
    }
    setting {
        namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
        name      = "UpdateLevel"
        value     = var.update_level
    }
    setting {
        namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
        name      = "InstanceRefreshEnabled"
        value     = var.instance_refresh_enabled
    }
    setting {
        namespace   = "aws:elasticbeanstalk:command"
        name        = "BatchSize"
        value       = var.BatchSize
    }
    setting {
        namespace   = "aws:elasticbeanstalk:command"
        name        = "DeploymentPolicy"
        value       = var.deployment_policy_type
    }
    setting {
        namespace   = "aws:elb:policies"
        name        = "ConnectionDrainingEnabled"
        value       = "true"
    }
    setting {
        name      = "SystemType"
        namespace = "aws:elasticbeanstalk:healthreporting:system"
        value     = "enhanced"
    }
    setting {
        name      = "ConfigDocument"
        namespace = "aws:elasticbeanstalk:healthreporting:system"
    
        value     = jsonencode(
            {
                Rules             = {
                    Environment = {
                        Application = {
                            ApplicationRequests4xx = {
                                Enabled = false
                            }
                        }
                        ELB         = {
                            ELBRequests4xx = {
                                Enabled = true
                            }
                        }
                    }
                }
                Version           = 1
            }
        )
    }
    setting {
        name      = "InstancePort"
        namespace = "aws:elb:listener:443"
        value     = "80"
    } 
    setting {
        name      = "InstanceProtocol"
        namespace = "aws:elb:listener:443"
        value     = "TCP"
    }
    setting {
        name      = "ListenerEnabled"
        namespace = "aws:elb:listener:443"
        value     = "true"
    }
    setting {
        name      = "ListenerProtocol"
        namespace = "aws:elb:listener:443"
        value     = "SSL"
    }
    setting {
        name      = "SSLCertificateId"
        namespace = "aws:elb:listener:443"
        value     = var.acm_certificate
    }
    setting {
        name      = "ManagedActionsEnabled"
        namespace = "aws:elasticbeanstalk:managedactions"
        value     = "true"
    }
    setting {
        name      = "Notification Endpoint"
        namespace = "aws:elasticbeanstalk:sns:topics"
        value     = "XXXXXXXXXXX"
    }
    setting {
        name      = "PreferredStartTime"
        namespace = "aws:elasticbeanstalk:managedactions"
        value     = "SUN:06:48"
    }
    setting {
        name      = "RetentionInDays"
        namespace = "aws:elasticbeanstalk:cloudwatch:logs"
        value     = "30"
    }
    setting {
        name      = "StreamLogs"
        namespace = "aws:elasticbeanstalk:cloudwatch:logs"
        value     = "true"
    }

    dynamic "setting" {
      for_each = var.env_vars
      content {
        namespace = "aws:elasticbeanstalk:application:environment"
        name      = setting.key
        value     = setting.value
      }
    }
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "description" {
  type        = string
  default     = ""
  description = "Short description of the Environment"
}

variable "Application_name" {
  type        = string
  description = "Elastic Beanstalk application name"
}

variable "aws_key_pair" {
  type        = string
  description = "Elastic Beanstalk application name"
}

variable "environment" {
  type        = string
  description = "Environment "
}

variable "environment_name" {
  type        = string
  description = "Environment"
}

variable "environment_type" {
  type        = string
  default     = "LoadBalanced"
  description = "Environment type, e.g. 'LoadBalanced' or 'SingleInstance'.  If setting to 'SingleInstance', `rolling_update_type` must be set to 'Time', `updating_min_in_service` must be set to 0, and `loadbalancer_subnets` will be unused (it applies to the ELB, which does not exist in SingleInstance environments)"
}

variable "loadbalancer_type" {
  type        = string
  description = "Load Balancer type, e.g. 'application' or 'classic'"
}

variable "loadbalancer_crosszone" {
  type        = bool
  default     = true
  description = "Configure the classic load balancer to route traffic evenly across all instances in all Availability Zones rather than only within each zone."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which to provision the AWS resources"
}

variable "loadbalancer_subnets" {
  type        = list(string)
  description = "List of subnets to place Elastic Load Balancer"
  default     = []
}

variable "application_subnets" {
  type        = list(string)
  description = "List of subnets to place EC2 instances"
  default     = []
}

variable "availability_zone" {
  type        = string
  default     = "Any 2"
  description = "Availability Zone selector"
}

variable "instance_type" {
  type        = string
  default     = ""
  description = "Instances type"
}

variable "proxy_server" {
  type        = string
  default     = "nginx"
  description = "Proxy Server type"
}

variable "managed_actions_enabled" {
  type        = bool
  default     = true
  description = "Enable managed platform updates. When you set this to true, you must also specify a `PreferredStartTime` and `UpdateLevel`"
}

variable "autoscale_min" {
  type        = number
  default     = 1
  description = "Minumum instances to launch"
}

variable "autoscale_max" {
  type        = number
  default     = 4
  description = "Maximum instances to launch"
}

variable "solution_stack_name" {
  type        = string
  description = "Elastic Beanstalk stack, e.g. Docker, Go, Node, Java, IIS. For more info, see https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html"
}

variable "wait_for_ready_timeout" {
  type        = string
  default     = "20m"
  description = "The maximum duration to wait for the Elastic Beanstalk Environment to be in a ready state before timing out"
}

variable "associate_public_ip_address" {
  type        = bool
  default     = false
  description = "Whether to associate public IP addresses to the instances"
}

variable "tier" {
  type        = string
  default     = "WebServer"
  description = "Elastic Beanstalk Environment tier, 'WebServer' or 'Worker'"
}

variable "version_label" {
  type        = string
  default     = ""
  description = "Elastic Beanstalk Application version to deploy"
}

variable "rolling_update_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable rolling update"
}

variable "deployment_policy_type" {
  type        = string
  default     = "AllAtOnce"
  description = "Whether to enable rolling update"
}

variable "rolling_update_type" {
  type        = string
  default     = "Health"
  description = "`Health` or `Immutable`. Set it to `Immutable` to apply the configuration change to a fresh group of instances"
}

variable "MinInstancesInService" {
  type        = number
  default     = 1
  description = "Minimum number of instances in service during update"
}

variable "BatchSize" {
  type        = number
  default     = 100
  description = "Maximum number of instances to update at once"
}

variable "health_streaming_enabled" {
  type        = bool
  default     = false
  description = "For environments with enhanced health reporting enabled, whether to create a group in CloudWatch Logs for environment health and archive Elastic Beanstalk environment health data. For information about enabling enhanced health, see aws:elasticbeanstalk:healthreporting:system."
}

variable "update_level" {
  type        = string
  default     = "minor"
  description = "The highest level of update to apply with managed platform updates"
}

variable "instance_refresh_enabled" {
  type        = bool
  default     = false
  description = "Enable weekly instance replacement."
}

variable "root_volume_size" {
  type        = number
  default     = null
  description = "The size of the EBS root volume"
}

variable "root_volume_type" {
  type        = string
  default     = null
  description = "The type of the EBS root volume"
}

variable "elb_scheme" {
  type        = string
  default     = "public"
  description = "Specify `internal` if you want to create an internal load balancer in your Amazon VPC so that your Elastic Beanstalk application cannot be accessed from outside your Amazon VPC"
}

variable "BatchSizeType" {
  type        = string
  default     = "Percentage"
  description = "The type of number that is specified in deployment_batch_size_type"
}

variable "deployment_batch_size" {
  type        = number
  default     = 1
  description = "Percentage or fixed number of Amazon EC2 instances in the Auto Scaling group on which to simultaneously perform deployments. Valid values vary per deployment_batch_size_type setting"
}

variable "deployment_ignore_health_check" {
  type        = bool
  default     = false
  description = "Do not cancel a deployment due to failed health checks"
}

variable "enhanced_reporting_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable \"enhanced\" health reporting for this environment.  If false, \"basic\" reporting is used.  When you set this to false, you must also set `enable_managed_actions` to false"
}

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "security_groups" {
  type        = list(string)
  description = "List of security groups to be allowed to connect to the EC2 instances"
  default     = []
}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "Map of custom ENV variables to be provided to the application running on Elastic Beanstalk, e.g. env_vars = { DB_USER = 'admin' DB_PASS = 'xxxxxx' }"
}

variable "service_role" {
  type        = string
  description = "IAM instance Service Profile role name"
}

variable "acm_certificate" {
  type        = string
  description = "ACM certificate for load balancer https listener"
}

variable "instance_profile_role" {
  type        = string
  description = "IAM instance Instance Profile role name"
}

variable "environment_url" {
  type        = string
  description = "The URL for the environment"
}

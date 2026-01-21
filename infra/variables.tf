variable "ec2_instance_name" {
  description = "The name tag for the EC2 instance"
  type        = string
  default     = "DemoEC2"
}

variable "codedeploy_app_name" {
  description = "The name of the CodeDeploy application"
  type        = string
  default     = "DemoWebApp"
}

variable "aws_security_group_name" {
  description = "The name of the security group for the EC2 instance"
  type        = string
  default     = "demo-web-sg"
}

variable "ec2_iam_role_name" {
  description = "The name of the IAM role for the EC2 instance"
  type        = string
  default     = "EC2CodeDeployRole"
}

variable "codedeploy_role_name" {
  description = "The name of the IAM role for CodeDeploy"
  type        = string
  default     = "CodeDeployServiceRole"
}

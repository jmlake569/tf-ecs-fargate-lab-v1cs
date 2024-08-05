variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "ecs-fargate-trend-demo"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    Reason = "ecs-fargate-trend-demo"
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
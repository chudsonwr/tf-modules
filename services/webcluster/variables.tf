variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "instance_size" {
  description = "EC2 instance size"
  type        = string
  default     = "t2.micro"
}

variable "asg_min" {
  description = "minimum instances in ASG"
  type        = number
  default     = 2
}

variable "asg_max" {
  description = "maximum instances in ASG"
  type        = number
  default     = 3
}
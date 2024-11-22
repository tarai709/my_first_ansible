variable "control_node_ip" {
  description = "Security group allows SSH from this IP address"
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\/[1-3]?[0-9]$", var.control_node_ip))
    error_message = "IP address must be a valid IPv4 CIDR that represents a network address like \"10.0.0.1/32\"."
  }
}

variable "ec2_names" {
  description = "If you want multiple instances at once, specify more than one value."
  type        = list(string)
}

variable "ami_id" {
  description = "Latest al2023(x86_64) is the default"
  type        = string
  default     = null
}

variable "subnet_name" {
  type = string
}

variable "security_group_name" {
  type = string
}

variable "associate_public_ip_address" {
  type    = bool
  default = false
}
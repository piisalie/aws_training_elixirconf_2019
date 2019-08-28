variable "instance_size" {
  default = {
    example = "t2.micro"
  }
}

variable "dns" {
  default = {
    example = "into.computer"
  }
}

variable "region" {}
variable "initial_asg" {
  type = bool
  default = false
}

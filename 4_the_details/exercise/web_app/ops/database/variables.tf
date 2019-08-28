variable "region" {}

variable "instance_size" {
  default = {
    example = "db.t2.small"
  }
}

variable "instance_storage" {
  default = {
    example = 20
  }
}

variable "backup_retention" {
  default = {
    example = 2
  }
}

variable "db_user" {}
variable "db_pw" {}

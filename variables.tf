variable "customer_name" {
  description = "Zimbra Course Contractor"
  type    = string

}

variable "participants" {
  description = "Number of participants that would be in the class (Counting Instructor)"
  type    = number
}

variable "training_zone" {
  description = "DNS Zone that would be provisioned for the class"
  type    = string
}

variable "vm1" {
  description = "Decides if vm1 must be provisioned"
  type = bool
  default = false
}

variable "vm2" {
  description = "Decides if vm2 must be provisioned"
  type = bool
  default = false
}

variable "tags" {
    description = "default tags for all resources"
    type = map
    default = {}
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "zports" {
  type    = list(number)
  default = [22, 80, 110, 143, 443, 587, 993, 995, 7071]
}

variable "instance" {
  type = map
  default = {
    "ami"  = "ami-fa9a1382"
    "type" = "t3.large"
  }
}
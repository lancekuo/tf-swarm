variable "subnet_public" {}
variable "subnet_public_app" {}
variable "subnet_private" {}
variable "subnet_on_public" {}
variable "subnet_per_zone" {}
variable "instance_per_subnet" {}
variable "swarm_manager_count" {}
variable "swarm_node_count" {}
variable "region" {}
variable "ami" {}
variable "project" {}
variable "domain" {}
variable "availability_zones" {}

variable "bastion_public_key_path" {}
variable "bastion_private_key_path" {}
variable "bastion_aws_key_name" {}
variable "manager_public_key_path" {}
variable "manager_private_key_path" {}
variable "manager_aws_key_name" {}
variable "node_public_key_path" {}
variable "node_private_key_path" {}
variable "node_aws_key_name" {}

variable "internal_zone_id" {}

provider "aws" {
    alias  = "${var.region}"
    region = "${var.region}"
}

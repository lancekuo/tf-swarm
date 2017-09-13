data "template_file" "user-data-bastion" {
    template = "${file("${path.module}/cloud-init/hostname")}"
    count    = 1

    vars {
        hostname = "${terraform.workspace}-${lower(var.project)}-bastion-${count.index}"
        domain   = "${var.domain}"
    }
}
resource "aws_key_pair" "swarm-bastion" {
    provider   = "aws.${var.aws_region}"
    key_name   = "${terraform.workspace}-${var.aws_region}-${var.rsa_key_bastion["aws_key_name"]}"
    public_key = "${file("${path.root}${var.rsa_key_bastion["public_key_path"]}")}"
}
resource "aws_instance" "swarm-bastion" {
    provider               = "aws.${var.aws_region}"
    count                  = 1
    instance_type          = "${var.instance_type_bastion}"
    ami                    = "${var.aws_ami_docker}"
    key_name               = "${aws_key_pair.swarm-bastion.id}"
    vpc_security_group_ids = ["${aws_security_group.swarm-bastion.id}"]
    subnet_id              = "${element(var.subnet_public_bastion_ids, var.count_bastion_subnet_on_public)}"

    tags  {
        Name           = "${terraform.workspace}-${lower(var.project)}-bastion-${count.index}"
        Env            = "${terraform.workspace}"
        Project        = "${var.project}"
        Role           = "bastion"
        Index          = "${count.index}"
    }
    user_data  = "${element(data.template_file.user-data-bastion.*.rendered, count.index)}"
}
resource "aws_eip" "swarm-bastion" {
    provider = "aws.${var.aws_region}"
    vpc      = true
    instance = "${aws_instance.swarm-bastion.id}"
}

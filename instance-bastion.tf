data "template_file" "user-data-bastion" {
    template = "${file("${path.module}/cloud-init/hostname")}"
    count    = 1

    vars {
        hostname = "${terraform.env}-${lower(var.project)}-bastion-${count.index}"
        domain   = "${var.domain}"
    }
}
resource "aws_key_pair" "swarm-bastion" {
    provider   = "aws.${var.region}"
    key_name   = "${terraform.env}-${var.region}-${var.bastion_aws_key_name}"
    public_key = "${file("${path.root}${var.bastion_public_key_path}")}"
}
resource "aws_instance" "swarm-bastion" {
    provider               = "aws.${var.region}"
    count                  = 1
    instance_type          = "t2.nano"
    ami                    = "${var.ami}"
    key_name               = "${aws_key_pair.swarm-bastion.id}"
    vpc_security_group_ids = ["${aws_security_group.swarm-bastion.id}"]
    subnet_id              = "${element(split(",", var.subnet_public), var.subnet_on_public)}"

    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = "${file("${path.root}${var.bastion_private_key_path}")}"
    }
    provisioner "remote-exec" {
        inline = [
            "sudo curl -L https://github.com/docker/machine/releases/download/v0.10.0/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine && chmod +x /tmp/docker-machine && sudo cp /tmp/docker-machine /usr/local/bin/docker-machine",
            "sudo curl -L https://github.com/docker/compose/releases/download/1.11.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose",
        ]
    }
    tags  {
        Name           = "${terraform.env}-${lower(var.project)}-bastion-${count.index}"
        Env            = "${terraform.env}"
        Project        = "${var.project}"
        Role           = "bastion"
        Index          = "${count.index}"
        Docker-machine = "sudo curl -L https://github.com/docker/machine/releases/download/v0.10.0/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine && chmod +x /tmp/docker-machine && sudo cp /tmp/docker-machine /usr/local/bin/docker-machine"
        Docker-compose = "sudo curl -L https://github.com/docker/compose/releases/download/1.11.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
    }
    user_data  = "${element(data.template_file.user-data-bastion.*.rendered, count.index)}"
}
resource "aws_eip" "swarm-bastion" {
    provider = "aws.${var.region}"
    vpc      = true
    instance = "${aws_instance.swarm-bastion.id}"
}

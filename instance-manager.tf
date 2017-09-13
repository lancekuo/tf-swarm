data "template_file" "hostname-manager" {
    template = "$${hostname}"
    count    = "${var.count_swarm_manager}"

    vars {
        hostname = "${terraform.workspace}-${lower(var.project)}-manager-${count.index}"
    }
}

data "template_file" "user-data-master" {
    template = "${file("${path.module}/cloud-init/hostname")}"
    count    = "${var.count_swarm_manager}"

    vars {
        hostname = "${element(data.template_file.hostname-manager.*.rendered, count.index)}"
        domain   = "${var.domain}"
    }
}
resource "aws_key_pair" "swarm-manager" {
    provider   = "aws.${var.aws_region}"
    key_name   = "${terraform.workspace}-${var.aws_region}-${var.rsa_key_manager["aws_key_name"]}"
    public_key = "${file("${path.root}${var.rsa_key_manager["public_key_path"]}")}"
}
resource "aws_instance" "swarm-manager" {
    provider               = "aws.${var.aws_region}"
    count                  = "${var.count_swarm_manager}"
    instance_type          = "${var.instance_type_manager}"
    ami                    = "${var.aws_ami_docker}"
    key_name               = "${aws_key_pair.swarm-manager.id}"
    vpc_security_group_ids = ["${aws_security_group.swarm-node.id}", "${aws_security_group.swarm-manager.id}", "${aws_security_group.swarm-outgoing-service.id}", "${aws_security_group.swarm-logstash.id}"]
    subnet_id              = "${element(var.subnet_public_app_ids, count.index)}"

    root_block_device = {
        volume_size = 20
        volume_type = "gp2"
    }

    connection {
        bastion_host        = "${aws_eip.swarm-bastion.public_ip}"
        bastion_user        = "ubuntu"
        bastion_private_key = "${file("${path.root}${var.rsa_key_bastion["private_key_path"]}")}"

        type                = "ssh"
        user                = "ubuntu"
        host                = "${self.private_ip}"
        private_key         = "${file("${path.root}${var.rsa_key_manager["private_key_path"]}")}"
    }

    provisioner "remote-exec" {
        inline = [" if [ ${count.index} -eq 0 ]; then sudo docker swarm init; else sudo docker swarm join ${aws_instance.swarm-manager.0.private_ip}:2377 --token $(docker -H ${aws_instance.swarm-manager.0.private_ip} swarm join-token -q manager); fi"]
    }
    tags  {
        Name    = "${element(data.template_file.hostname-manager.*.rendered, count.index)}"
        Env     = "${terraform.workspace}"
        Project = "${var.project}"
        Role    = "manager"
        Index   = "${count.index}"
    }
    user_data = "${element(data.template_file.user-data-master.*.rendered, count.index)}"
}

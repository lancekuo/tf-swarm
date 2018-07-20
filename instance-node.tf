data "template_file" "hostname-node" {
    template = "$${hostname}"
    count    = "${var.count_swarm_node}"

    vars {
        hostname = "${terraform.workspace}-${lower(var.project)}-node-${count.index}"
    }
}

data "template_file" "user-data-node" {
    template = "${file("${path.module}/cloud-init/hostname")}"
    count    = "${var.count_swarm_node}"

    vars {
        hostname = "${element(data.template_file.hostname-node.*.rendered, count.index)}"
        domain   = "${var.domain}"
    }
}
resource "aws_key_pair" "node" {
    key_name   = "${terraform.workspace}-${var.project}-${var.rsa_key_node["aws_key_name"]}"
    public_key = "${file("${path.root}${var.rsa_key_node["public_key_path"]}")}"
}
resource "aws_instance" "node" {
    count                  = "${var.count_swarm_node}"
    instance_type          = "${var.instance_type_node}"
    ami                    = "${var.aws_ami_docker}"
    key_name               = "${aws_key_pair.node.id}"
    vpc_security_group_ids = ["${aws_security_group.node.id}", "${aws_security_group.swarm-outgoing-service.id}", "${aws_security_group.logstash.id}"]
    subnet_id              = "${element(var.subnet_public_app_ids, count.index)}"
    monitoring             = true

    root_block_device = {
        volume_size = 20
        volume_type = "gp2"
    }

    connection {
        bastion_host        = "${aws_eip.bastion.public_ip}"
        bastion_user        = "ubuntu"
        bastion_private_key = "${file("${path.root}${var.rsa_key_bastion["private_key_path"]}")}"

        type                = "ssh"
        user                = "ubuntu"
        host                = "${self.private_ip}"
        private_key         = "${file("${path.root}${var.rsa_key_node["private_key_path"]}")}"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo docker swarm join ${aws_instance.manager.0.private_ip}:2377 --token $(docker -H ${aws_instance.manager.0.private_ip} swarm join-token -q worker)"
        ]
    }
# drain and remove the node on destroy
    provisioner "remote-exec" {
        when = "destroy"

        inline = [
            "sudo docker node update --availability drain ${self.tags.Name}"
        ]
        on_failure = "continue"
        connection {
            bastion_host        = "${aws_eip.bastion.public_ip}"
            bastion_user        = "ubuntu"
            bastion_private_key = "${file("${path.root}${var.rsa_key_bastion["private_key_path"]}")}"

            type                = "ssh"
            user                = "ubuntu"
            host                = "${aws_instance.manager.0.private_ip}"
            private_key         = "${file("${path.root}${var.rsa_key_manager["private_key_path"]}")}"
        }
    }

    provisioner "remote-exec" {
        when = "destroy"

        inline = [
            "sudo docker swarm leave",
        ]
        on_failure = "continue"
    }

    provisioner "remote-exec" {
        when = "destroy"

        inline = [
            "sudo docker node rm --force ${self.tags.Name}"
        ]
        on_failure = "continue"
        connection {
            bastion_host        = "${aws_eip.bastion.public_ip}"
            bastion_user        = "ubuntu"
            bastion_private_key = "${file("${path.root}${var.rsa_key_bastion["private_key_path"]}")}"

            type                = "ssh"
            user                = "ubuntu"
            host                = "${aws_instance.manager.0.private_ip}"
            private_key         = "${file("${path.root}${var.rsa_key_manager["private_key_path"]}")}"
        }
    }
    tags  {
        Name        = "${element(data.template_file.hostname-node.*.rendered, count.index)}"
        Environment = "${terraform.workspace}"
        Project     = "${var.project}"
        Role        = "node"
        Index       = "${count.index}"
        Retention   = 365
    }
    user_data  = "${element(data.template_file.user-data-node.*.rendered, count.index)}"
}

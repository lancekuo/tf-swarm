resource "aws_key_pair" "swarm-node" {
    provider   = "aws.${var.region}"
    key_name   = "${terraform.env}-${var.region}-${var.node_aws_key_name}"
    public_key = "${file("${path.root}${var.node_public_key_path}")}"
}

data "template_file" "user-data-node" {
    template = "${file("${path.module}/cloud-init/hostname")}"
    count    = "${var.swarm_node_count}"

    vars {
        hostname = "${terraform.env}-${lower(var.project)}-node-${count.index}"
        domain   = "${var.domain}"
    }
}
resource "aws_instance" "swarm-node" {
    provider               = "aws.${var.region}"
    count                  = "${var.swarm_node_count}"
    instance_type          = "t2.small"
    ami                    = "${var.ami}"
    key_name               = "${aws_key_pair.swarm-node.id}"
    vpc_security_group_ids = ["${aws_security_group.swarm-node.id}", "${aws_security_group.swarm-outgoing-service.id}", "${aws_security_group.swarm-logstash.id}"]
    subnet_id              = "${element(split(",", var.subnet_public_app), (count.index+var.swarm_manager_count))}"

    root_block_device = {
        volume_size = 20
    }

    connection {
        bastion_host        = "${aws_eip.swarm-bastion.public_ip}"
        bastion_user        = "ubuntu"
        bastion_private_key = "${file("${path.root}${var.bastion_private_key_path}")}"

        type                = "ssh"
        user                = "ubuntu"
        host                = "${self.private_ip}"
        private_key         = "${file("${path.root}${var.node_private_key_path}")}"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo docker swarm join ${aws_instance.swarm-manager.0.private_ip}:2377 --token $(docker -H ${aws_instance.swarm-manager.0.private_ip} swarm join-token -q worker)"
        ]
    }
    tags  {
        Name    = "${terraform.env}-${lower(var.project)}-node-${count.index}"
        Env     = "${terraform.env}"
        Project = "${var.project}"
        Role    = "node"
        Index   = "${count.index}"
    }
    user_data  = "${element(data.template_file.user-data-node.*.rendered, count.index)}"
    depends_on = [
        "aws_instance.swarm-manager"
    ]
}

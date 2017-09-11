resource "aws_volume_attachment" "ebs_att" {
    provider     = "aws.${var.aws_region}"
    device_name  = "/dev/xvdg"
    volume_id    = "${aws_ebs_volume.storage-metric.id}"
    instance_id  = "${element(aws_instance.swarm-node.*.id, 0)}"
    skip_destroy = true
    force_detach = false
}
resource "aws_ebs_volume" "storage-metric" {
    provider          = "aws.${var.aws_region}"
    availability_zone = "${element(var.availability_zones, (length(aws_instance.swarm-node.*.id)-1+var.count_swarm_manager))}"
    size              = 100
    lifecycle         = {
        ignore_changes  = "*"
        prevent_destroy = true
    }
    tags  {
        Name    = "${terraform.workspace}-${lower(var.project)}-storage-metric"
        Env     = "${terraform.workspace}"
        Project = "${var.project}"
        Role    = "storage"
    }
}

resource "null_resource" "ebs_trigger" {
    triggers {
        att_id = "${aws_volume_attachment.ebs_att.id}"
    }

    provisioner "remote-exec" {
        inline = [
            "if [ -d /opt/prometheus/ ];then echo \"The folder exists.\";else sudo mkdir /opt/prometheus;echo \"Mount point created.\";fi",
#            "sudo parted /dev/xvdg --script -- mklabel msdos mkpart primary ext4 0 -1",
#            "sudo mkfs.ext4 -F /dev/xvdg1",
            "if ! grep -e \"$$(sudo file -s /dev/xvdg1|awk -F\\  '{print $8}')    /opt/prometheus\" /etc/fstab 1> /dev/null;then echo \"`sudo file -s /dev/xvdg1|awk -F\\  '{print $8}'`    /opt/prometheus    ext4    defaults,errors=remount-ro    0    0\"| sudo tee -a /etc/fstab;else echo 'Fstab has the mount point'; fi ",
            "if grep -qs '/opt/prometheus' /proc/mounts; then echo \"/opt/prometheus has mounted.\"; else sudo mount `sudo file -s /dev/xvdg1|awk -F\\  '{print $8}'` /opt/prometheus; fi",
        ]
        connection {
            bastion_host        = "${aws_eip.swarm-bastion.public_ip}"
            bastion_user        = "ubuntu"
            bastion_private_key = "${file("${path.root}${var.bastion_private_key_path}")}"

            type                = "ssh"
            user                = "ubuntu"
            host                = "${element(aws_instance.swarm-node.*.private_ip, 0)}"
            private_key         = "${file("${path.root}${var.node_private_key_path}")}"
        }
    }
    provisioner "remote-exec" {
        inline = [
            "docker node update --label-add type=storage ${element(aws_instance.swarm-node.*.tags.Name, 0)}",
            "docker node update --label-add type=internal ${element(aws_instance.swarm-manager.*.tags.Name, length(aws_instance.swarm-manager.*.id)-1)}",
        ]
        connection {
            bastion_host        = "${aws_eip.swarm-bastion.public_ip}"
            bastion_user        = "ubuntu"
            bastion_private_key = "${file("${path.root}${var.bastion_private_key_path}")}"

            type                = "ssh"
            user                = "ubuntu"
            host                = "${element(aws_instance.swarm-manager.*.private_ip, 0)}"
            private_key         = "${file("${path.root}${var.manager_private_key_path}")}"
        }
    }
}

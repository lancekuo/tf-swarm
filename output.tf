output "swarm_manager" {
    value = "${aws_instance.swarm-manager.*.private_dns}"
}
output "swarm_node" {
    value = "${aws_instance.swarm-node.*.private_dns}"
}
output "bastion_public_ip" {
    value = "${aws_eip.swarm-bastion.public_ip}"
}
output "bastion_private_ip" {
    value = "${aws_eip.swarm-bastion.private_ip}"
}

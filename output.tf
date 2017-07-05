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
output "node_list_string" {
    value = "${join(",",aws_instance.swarm-node.*.id)}"
}

output "security_group_node_id" {
    value = "${aws_security_group.swarm-node.id}"
}

output "elb_grafana_dns" {
    value = "${aws_elb.grafana.dns_name}"
}

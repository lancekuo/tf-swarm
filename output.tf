output "swarm_manager" {
    value = "${aws_instance.manager.*.private_dns}"
}
output "swarm_node" {
    value = "${aws_instance.node.*.private_dns}"
}
output "bastion_public_ip" {
    value = "${aws_eip.bastion.public_ip}"
}
output "bastion_private_ip" {
    value = "${aws_eip.bastion.private_ip}"
}
output "node_list_string" {
    value = "${join(",",aws_instance.node.*.id)}"
}

output "security_group_node_id" {
    value = "${aws_security_group.node.id}"
}

output "elb_grafana_dns" {
    value = "${aws_elb.grafana.dns_name}"
}
output "elb_kibana_dns" {
    value = "${aws_elb.kibana.dns_name}"
}
output "logstash_internal_dns" {
    value = "${aws_route53_record.logstash.fqdn}"
}

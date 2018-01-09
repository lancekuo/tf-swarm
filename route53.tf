resource "aws_route53_record" "logstash" {
    zone_id  = "${var.route53_internal_zone_id}"
    name     = "${terraform.workspace}-logstash.${var.project}.internal"
    type     = "A"
    ttl      = "300"
    records  = ["${aws_instance.swarm-node.*.private_ip}", "${aws_instance.swarm-manager.*.private_ip}"]
}


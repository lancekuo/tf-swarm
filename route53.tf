resource "aws_route53_record" "logstash" {
    provider = "aws.${var.region}"
    zone_id  = "${var.internal_zone_id}"
    name     = "${terraform.env}-logstash.${var.project}.internal"
    type     = "A"
    ttl      = "300"
    records  = ["${aws_instance.swarm-node.*.private_ip}", "${aws_instance.swarm-manager.*.private_ip}"]
}

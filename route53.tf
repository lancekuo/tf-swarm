resource "aws_route53_record" "logstash" {
    zone_id  = "${var.route53_internal_zone_id}"
    name     = "logstash"
    type     = "A"
    ttl      = "300"
    records  = ["${aws_instance.node.*.private_ip}", "${aws_instance.manager.*.private_ip}"]
}


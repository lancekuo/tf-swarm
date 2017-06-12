resource "aws_elb" "grafana" {
    provider = "aws.${var.region}"
    name = "${terraform.env}-grafana"

    subnets         = ["${split(",", var.subnet_public_app)}"]
    security_groups = ["${aws_security_group.grafana-elb.id}"]
    instances       = ["${aws_instance.swarm-node.*.id}", "${aws_instance.swarm-manager.*.id}"]

    listener {
        instance_port     = 3000
        instance_protocol = "http"
        lb_port           = 80
        lb_protocol       = "http"
    }
    health_check {
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 4
        target              = "TCP:3000"
        interval            = 5
    }
    tags  {
        Env     = "${terraform.env}"
        Project = "${var.project}"
    }
}

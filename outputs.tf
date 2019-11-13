output "elastic-ips" {
  value = ["${aws_eip.ovpn-eip.*.public_ip}"]
}

output "sns_topic_arn" {
  value = "${aws_sns_topic.slack-notify.arn}"
}

output "zone_id" {
  value = "${aws_route53_zone.primary.zone_id}"
}

output "sns_topic" {
  value = "${aws_sns_topic.slack-notify.arn}"
}

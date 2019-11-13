resource "aws_sns_topic" "slack-notify" {
  name = "vpn-alert"
  provider = "aws.east-1"
}

resource "aws_sns_topic_subscription" "subscription" {
  topic_arn = "${aws_sns_topic.slack-notify.arn}"
  protocol = "lambda"
  provider = "aws.east-1"
  endpoint = "${aws_lambda_function.slack.arn}"
}

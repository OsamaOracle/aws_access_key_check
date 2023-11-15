locals {
  tags = {
    Environment = var.environment,
    Owner       = "jack"
  }
}

data "aws_caller_identity" "current" {}

data "archive_file" "results_check" {
  type        = "zip"
  source_dir  = "../functions/access_key_results_check"
  output_path = "../functions/results_check.zip"
}

module "results_check" {
  source           = "git@github.com:tutuka/aws-lambda.git?ref=tags/v1.0"
  name             = "access_key_results_check"
  filename         = "../functions/results_check.zip"
  handler          = "index.lambda_handler"
  memory_size      = 128
  runtime          = "python3.6"
  source_code_hash = data.archive_file.results_check.output_base64sha256
  timeout          = 120
  attach_policy    = true
  policy           = data.aws_iam_policy_document.results_check.json
  tags = merge(
    {
      Name = "access_key_results_check"
    },
    local.tags
  )
}

data "archive_file" "check_key_age" {
  type        = "zip"
  source_dir  = "../functions/access_key_check_key_age"
  output_path = "../functions/check_key_age.zip"
}

module "check_key_age" {
  source           = "git@github.com:tutuka/aws-lambda.git?ref=tags/v1.0"
  name             = "access_key_check_key_age"
  filename         = "../functions/check_key_age.zip"
  handler          = "index.lambda_handler"
  memory_size      = 128
  runtime          = "python3.6"
  source_code_hash = data.archive_file.check_key_age.output_base64sha256
  attach_policy    = true
  policy           = data.aws_iam_policy_document.check_key_age.json
  tags = merge(
    {
      Name = "access_key_check_key_age"
    },
    local.tags
  )
}

data "archive_file" "deactivate_key" {
  type        = "zip"
  source_dir  = "../functions/access_key_deactivate_key"
  output_path = "../functions/deactivate_key.zip"
}

module "deactivate_key" {
  source           = "git@github.com:tutuka/aws-lambda.git?ref=tags/v1.0"
  name             = "access_key_deactivate_key"
  filename         = "../functions/deactivate_key.zip"
  handler          = "index.lambda_handler"
  memory_size      = 128
  runtime          = "python3.6"
  source_code_hash = data.archive_file.deactivate_key.output_base64sha256
  attach_policy    = true
  policy           = data.aws_iam_policy_document.deactivate_key.json
  tags = merge(
    {
      Name = "access_key_deactivate_key"
    },
    local.tags
  )
}

data "archive_file" "notify_user" {
  type        = "zip"
  source_dir  = "../functions/access_key_notify_user"
  output_path = "../functions/notify_user.zip"
}

module "notify_user" {
  source           = "git@github.com:tutuka/aws-lambda.git?ref=tags/v1.0"
  name             = "access_key_notify_user"
  filename         = "../functions/notify_user.zip"
  handler          = "index.lambda_handler"
  memory_size      = 128
  runtime          = "python3.6"
  source_code_hash = data.archive_file.notify_user.output_base64sha256
  attach_policy    = true
  policy           = data.aws_iam_policy_document.notify_user.json
  environment_variable = {
    DEFAULT_EMAIL = var.default_email,
    REGION        = var.region
  }
  tags = merge(
    {
      Name = "access_key_notify_user"
    },
    local.tags
  )
}

module "stepfunctions_role" {
  source             = "git@github.com:tutuka/aws-iam-role.git?ref=v1.0"
  name               = "stepfunctions_access_key_check"
  assume_role_policy = data.aws_iam_policy_document.stepfunctions_assume_role_policy
  inline_policies = {
    stepfunctions = data.aws_iam_policy_document.stepfunctions_policy.json
  }
}

resource "aws_sfn_state_machine" "access_key_check" {
  name       = "access_key_check"
  role_arn   = module.stepfunctions_role.arn
  definition = templatefile("./access_key_check_definitions.json",
    {
      results_check_arn = module.results_check.arn,
      check_key_age_arn = module.check_key_age.arn,
      deactivate_key_arn = module.deactivate_key.arn,
      notify_user_arn = module.notify_user.arn
    }
  )
  tags = merge(
    {
      Name = "access_key_check"
    },
    local.tags
  )
}

data "aws_iam_policy_document" "cloudwatch_event_assume_policy" {
  statement {
    sid     = "trustCloudwatchEvents"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "cloudwatch_event_stepfunctions" {
  statement {
    sid       = "allowStepFunctions"
    actions   = ["states:StartExecution"]
    effect    = "Allow"
    resources = [aws_sfn_state_machine.access_key_check.id]
  }
}

module "cloudwatch_event_role" {
  source             = "git@github.com:tutuka/aws-iam-role.git?ref=v1.0"
  name               = "cloudwatch_access_key_check_rule"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_event_assume_policy
  inline_policies = {
    stepfunctions = data.aws_iam_policy_document.cloudwatch_event_stepfunctions.json
  }
}

resource "aws_cloudwatch_event_rule" "access-key-check" {
  name                = "access-key-check"
  schedule_expression = "cron(0 6 * * ? *)"
  description         = "Scheduled execution of access key check step funtions state machine"
  role_arn            = module.cloudwatch_event_role.arn
}

resource "aws_cloudwatch_event_target" "rule-target" {
  rule      = aws_cloudwatch_event_rule.access-key-check.name
  target_id = "access-key-check"
  arn       = aws_sfn_state_machine.access_key_check.id
  role_arn  = module.cloudwatch_event_role.arn
}

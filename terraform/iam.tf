data "aws_iam_policy_document" "results_check" {
  statement {
    sid    = "AllowTrustedAdvisor"
    effect = "Allow"
    actions = [
      "support:DescribeTrustedAdvisorCheckRefreshStatuses",
      "support:DescribeTrustedAdvisorCheckResult",
      "support:RefreshTrustedAdvisorCheck",
      "support:DescribeTrustedAdvisorChecks"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "check_key_age" {
  statement {
    sid    = "AllowIamListKey"
    effect = "Allow"
    actions = [
      "iam:ListAccessKeys"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "deactivate_key" {
  statement {
    sid    = "AllowIamUpdateKey"
    effect = "Allow"
    actions = [
      "iam:UpdateAccessKey"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "notify_user" {
  statement {
    sid    = "AllowSendEmail"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]
    resources = [format("arn:aws:ses:%s:%s:identity/%s.tutuka.cloud", var.region, data.aws_caller_identity.current.account_id, var.environment)]
    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = [format("aws-notifications@%s.tutuka.cloud", var.environment)]
    }
  }

  statement {
    sid       = "AllowListUserTags"
    effect    = "Allow"
    actions   = ["iam:ListUserTags"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "stepfunctions_assume_role_policy" {
  statement {
    sid     = "TrustAccounts"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "stepfunctions_policy" {
  statement {
    sid = "AllowXRay"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid     = "InvokeLambdas"
    actions = ["lambda:InvokeFunction"]
    effect  = "Allow"
    resources = [
      module.results_check.arn,
      module.check_key_age.arn,
      module.deactivate_key.arn,
      module.notify_user.arn
    ]
  }
}

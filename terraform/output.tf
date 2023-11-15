output "results_check_arn" {
  value = module.results_check.arn
}

output "results_check_iam_role_arn" {
  value = module.results_check.iam_role_arn
}

output "check_key_age_arn" {
  value = module.check_key_age.arn
}

output "check_key_age_iam_role_arn" {
  value = module.results_check.iam_role_arn
}

output "deactivate_key_arn" {
  value = module.deactivate_key.arn
}

output "deactivate_key_iam_role_arn" {
  value = module.deactivate_key.iam_role_arn
}

output "notify_user_arn" {
  value = module.notify_user.arn
}

output "notify_user_iam_role_arn" {
  value = module.notify_user.iam_role_arn
}

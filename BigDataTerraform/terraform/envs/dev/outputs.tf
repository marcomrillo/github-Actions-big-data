output "raw_bucket_name" {
  value = module.raw_bucket.bucket_name
}

output "staging_bucket_name" {
  value = module.staging_bucket.bucket_name
}

output "analytics_bucket_name" {
  value = module.analytics_bucket.bucket_name
}
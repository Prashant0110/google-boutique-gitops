module "application_s3" {
  source = "../../modules/s3"

  project       = "google-boutique"
  environment   = "dev"
  bucket_suffix = "apex"
}
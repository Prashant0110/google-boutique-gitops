module "cloudtrail" {
  source = "../../modules/cloudtrail"

  project       = "google-boutique"
  environment   = "dev"
  bucket_suffix = "apex"
}
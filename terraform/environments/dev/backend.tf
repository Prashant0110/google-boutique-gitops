terraform {
  backend "s3" {
    bucket       = "google-boutique-terraform-state-333982363119"
    key          = "google-boutique/dev/terraform.tfstate"
    region       = "us-west-2"
    profile      = "terraform-user"
    encrypt      = true
    use_lockfile = true
  }
}

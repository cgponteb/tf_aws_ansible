provider "aws" {
  profile = var.profile
  region  = var.region_master
  alias   = "region_master"
}

provider "aws" {
  profile = var.profile
  region  = var.region_worker
  alias   = "region_worker"
}
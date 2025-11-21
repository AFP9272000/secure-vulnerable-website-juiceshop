terraform {
  backend "s3" {
    bucket         = "afp9272000-juiceshop-tfstate-1763232924"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "afp9272000-juiceshop-state-lock"
  }
}

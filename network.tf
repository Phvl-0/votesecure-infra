data "aws_vpc" "default" {
  default = true
}

resource "aws_key_pair" "main" {
  key_name   = "votesecure-tf-key"
  public_key = file("${path.module}/votesecure-tf.pub")
}

resource "aws_security_group" "main" {
  #checkov:skip=CKV_AWS_260:Caddy needs port 80 for the Let's Encrypt challenge and the HTTPS redirect
  #checkov:skip=CKV_AWS_382:VM needs outbound for updates, image pulls, certificates and SSM; tighten later
  name        = "votesecure-tf-sg"
  description = "votesecure ssh from my ip, web open"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "ssh from my ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }
  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Terraform removes the default allow-all egress rule, so we add it back
  egress {
    description = "all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

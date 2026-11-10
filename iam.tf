data "aws_iam_policy_document" "vm_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vm" {
  name               = "votesecure-vm-role"
  assume_role_policy = data.aws_iam_policy_document.vm_assume.json
}

resource "aws_iam_role_policy_attachment" "vm_ssm" {
  role       = aws_iam_role.vm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "vm" {
  name = "votesecure-vm-profile"
  role = aws_iam_role.vm.name
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "vm_params" {
  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:eu-north-1:${data.aws_caller_identity.current.account_id}:parameter/votesecure/*"]
  }
}

resource "aws_iam_role_policy" "vm_params" {
  name   = "read-votesecure-parameters"
  role   = aws_iam_role.vm.name
  policy = data.aws_iam_policy_document.vm_params.json
}

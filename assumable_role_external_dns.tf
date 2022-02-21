# External-DNS
module "iam_assumable_role_external_dns" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~>4.7"

  create_role                   = true
  role_name                     = "${var.cluster_name}-external-dns"
  provider_url                  = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:external-dns"]
  number_of_role_policy_arns    = 1
}

resource "aws_iam_policy" "external_dns" {
  name_prefix = "${var.cluster_name}-external-dns"
  description = "EKS external_dns policy for the ${var.cluster_name} cluster"
  policy      = data.aws_iam_policy_document.external_dns.json
}

data "aws_iam_policy_document" "external_dns" {
  statement {
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets"
    ]

    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "route53:GetChange"
    ]

    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]

    resources = ["*"]
  }
}

# Cert-Manager
module "iam_assumable_role_cert_manager" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~>4.7"

  create_role                   = true
  role_name                     = "${var.cluster_name}-cert-manager"
  provider_url                  = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  role_policy_arns              = [aws_iam_policy.cert_manager.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:cert-manager:cert-manager"]
  number_of_role_policy_arns    = 1
}

resource "aws_iam_policy" "cert_manager" {
  name_prefix = "${var.cluster_name}-cert-manager"
  description = "EKS cert-manager policy for the ${var.cluster_name} cluster"
  policy      = data.aws_iam_policy_document.cert_manager.json
}

data "aws_iam_policy_document" "cert_manager" {
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
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]

    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "route53:ListHostedZonesByName"
    ]

    resources = ["*"]
  }
}

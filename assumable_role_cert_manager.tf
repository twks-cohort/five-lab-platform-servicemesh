locals {
  cert_manager_account_namespace = "cert-manager"
  cert_manager_service_account_name = "${var.cluster_name}-cert-manager"
}

# Cert-Manager
module "iam_assumable_role_cert_manager" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.1.0"

  create_role                   = true
  role_name                     = "${var.cluster_name}-cert-manager"
  provider_url                  = replace(data.terraform_remote_state.eks.outputs.eks_cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.cert_manager.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.cert_manager_account_namespace}:${local.cert_manager_service_account_name}"]
  number_of_role_policy_arns    = 1
}

resource "aws_iam_policy" "cert_manager" {
  name_prefix = "${var.cluster_name}-cert-manager"
  description = "EKS cert-manager policy for the ${var.cluster_name} cluster"
  policy      = data.aws_iam_policy_document.cert_manager.json
}

data "aws_iam_policy_document" "cert_manager" {
  statement {
    sid    = "${var.cluster_name}CertManagerChanges"
    effect = "Allow"

    actions = [
      "route53:GetChange"
    ]

    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    sid    = "${var.cluster_name}CertManagerResourceRecordChanges"
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]

    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    sid    = "${var.cluster_name}CertManagerListHostedZones"
    effect = "Allow"

    actions = [
      "route53:ListHostedZonesByName"
    ]

    resources = ["*"]
  }
}

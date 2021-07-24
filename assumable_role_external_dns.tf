locals {
  external_dns_account_namespace    = "kube-system"
  external_dns_service_account_name = "${var.cluster_name}-external-dns"
}

# External-DNS
module "iam_assumable_role_external_dns" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.1.0"

  create_role                   = true
  role_name                     = "${var.cluster_name}-external-dns"
  provider_url                  = replace(data.terraform_remote_state.eks.outputs.eks_cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.external_dns_account_namespace}:${local.external_dns_service_account_name}"]
  number_of_role_policy_arns    = 1
}

resource "aws_iam_policy" "external_dns" {
  name_prefix = "${var.cluster_name}-external-dns"
  description = "EKS external_dns policy for the ${var.cluster_name} cluster"
  policy      = data.aws_iam_policy_document.external_dns.json
}

data "aws_iam_policy_document" "external_dns" {
  statement {
    sid    = "${var.cluster_name}ExternalDNSRecords"
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets"
    ]

    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    sid    = "${var.cluster_name}ExternalDNSChanges"
    effect = "Allow"

    actions = [
      "route53:GetChange"
    ]

    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    sid    = "${var.cluster_name}HostedZones"
    effect = "Allow"

    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]

    resources = ["*"]
  }
}

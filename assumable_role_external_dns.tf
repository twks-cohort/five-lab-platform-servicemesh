module "external_dns_irsa" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version               = "~> 5.1.0"

  role_name             = "${var.cluster_name}-external-dns"
  attach_external_dns_policy = true

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["istio-system:external-dns"]
    }
  }
}

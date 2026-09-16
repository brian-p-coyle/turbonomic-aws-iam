# ---------------------------------------------------------------------------
# Member account IAM resources
#
# WHY NOT for_each?
# Terraform provider aliases are static — they cannot be generated dynamically
# at plan/apply time. Each member account therefore needs its own resource
# blocks that explicitly reference its provider alias. Add or remove blocks
# to match the provider aliases defined in provider.tf and the account IDs in
# var.member_account_ids / terraform.tfvars.
#
# ADDING A NEW MEMBER ACCOUNT
# 1. Add a provider block in provider.tf  (alias = "member_<account_id>")
# 2. Copy one of the policy + role + attachment triplets below and update:
#    - provider alias references
#    - the account ID in the resource name suffix
#    - the description strings
# 3. Add the account ID to member_account_ids in terraform.tfvars
# ---------------------------------------------------------------------------

locals {
  member_222 = "222222222222"
  member_333 = "333333333333"
}

# ---------------------------------------------------------------------------
# Shared member policy document (same for all member accounts)
# Excludes management-only permissions: organizations:*, pricing:*, s3:*,
# sts:AssumeRole, ce:GetReservationUtilization, ce:GetSavingsPlansUtilizationDetails
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "turbonomic_member_policy" {
  statement {
    sid       = "IAMIdentityCheck"
    effect    = "Allow"
    actions   = ["iam:GetUser"]
    resources = ["*"]
  }
  statement {
    sid    = "RegionsAndZones"
    effect = "Allow"
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeRegions",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "CloudWatchMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:ListTagsForResource",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "PerformanceInsights"
    effect = "Allow"
    actions = [
      "pi:GetResourceMetrics",
      "pi:ListAvailableResourceMetrics",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "EC2Discovery"
    effect = "Allow"
    actions = [
      "ec2:DescribeAddresses",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeReservedInstances",
      "ec2:DescribeReservedInstancesModifications",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AutoScalingDiscovery"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeTags",
      "autoscaling:DescribeLaunchConfigurations",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "LaunchTemplateDiscovery"
    effect    = "Allow"
    actions   = ["ec2:DescribeLaunchTemplateVersions"]
    resources = ["*"]
  }
  statement {
    sid    = "EKSDiscovery"
    effect = "Allow"
    actions = [
      "eks:ListClusters",
      "eks:DescribeCluster",
      "eks:ListNodegroups",
      "eks:DescribeNodegroup",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "EBSDiscovery"
    effect = "Allow"
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeVolumesModifications",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "CloudTrailEBSHistory"
    effect    = "Allow"
    actions   = ["cloudtrail:LookupEvents"]
    resources = ["*"]
  }
  statement {
    sid    = "RDSAndAuroraDiscovery"
    effect = "Allow"
    actions = [
      "rds:DescribeDBClusters",
      "rds:DescribeDBInstances",
      "rds:DescribeDBParameters",
      "rds:DescribeOrderableDBInstanceOptions",
      "rds:DescribeReservedDBInstances",
      "rds:ListTagsForResource",
      "rds:DescribeGlobalClusters",
      "rds:DescribeBlueGreenDeployments",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "RedshiftDiscovery"
    effect = "Allow"
    actions = [
      "redshift:DescribeClusters",
      "redshift:DescribeTags",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "SavingsAndReservations"
    effect = "Allow"
    actions = [
      "savingsplans:DescribeSavingsPlans",
      "savingsplans:DescribeSavingsPlansOfferingRates",
    ]
    resources = ["*"]
  }
}

# ---------------------------------------------------------------------------
# Member account: 222222222222
# ---------------------------------------------------------------------------
resource "aws_iam_policy" "turbonomic_member_222" {
  provider    = aws.member_222222222222
  name        = "${var.policy_name}-member"
  description = "Turbonomic read-only monitoring permissions for member account ${local.member_222}."
  policy      = data.aws_iam_policy_document.turbonomic_member_policy.json
  tags        = var.tags
}

resource "aws_iam_role" "turbonomic_member_222" {
  provider    = aws.member_222222222222
  name        = var.member_role_name
  description = "Assumed by Turbonomic via the management account role to monitor member account ${local.member_222}."
  tags        = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TrustManagementAccountRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:role/${var.management_role_name}"
        }
        Action    = "sts:AssumeRole"
        Condition = var.external_id != "" ? { StringEquals = { "sts:ExternalId" = var.external_id } } : {}
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "turbonomic_member_222" {
  provider   = aws.member_222222222222
  role       = aws_iam_role.turbonomic_member_222.name
  policy_arn = aws_iam_policy.turbonomic_member_222.arn
}

# ---------------------------------------------------------------------------
# Member account: 333333333333
# ---------------------------------------------------------------------------
resource "aws_iam_policy" "turbonomic_member_333" {
  provider    = aws.member_333333333333
  name        = "${var.policy_name}-member"
  description = "Turbonomic read-only monitoring permissions for member account ${local.member_333}."
  policy      = data.aws_iam_policy_document.turbonomic_member_policy.json
  tags        = var.tags
}

resource "aws_iam_role" "turbonomic_member_333" {
  provider    = aws.member_333333333333
  name        = var.member_role_name
  description = "Assumed by Turbonomic via the management account role to monitor member account ${local.member_333}."
  tags        = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TrustManagementAccountRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:role/${var.management_role_name}"
        }
        Action    = "sts:AssumeRole"
        Condition = var.external_id != "" ? { StringEquals = { "sts:ExternalId" = var.external_id } } : {}
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "turbonomic_member_333" {
  provider   = aws.member_333333333333
  role       = aws_iam_role.turbonomic_member_333.name
  policy_arn = aws_iam_policy.turbonomic_member_333.arn
}

# Add more member account blocks here following the same pattern.

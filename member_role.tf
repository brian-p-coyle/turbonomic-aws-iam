# ---------------------------------------------------------------------------
# Member account cross-account IAM role
#
# This role is deployed into each member account. It trusts the management
# account role so Turbonomic can assume it transitively after first assuming
# the management account role.
#
# In practice you would deploy this with CloudFormation StackSets across your
# organization. This Terraform resource covers the case where you want to
# provision a known, static list of member account IDs directly.
#
# Each role is created using the aws_iam_role resource with a for_each over
# var.member_account_ids. Because these roles live in different accounts you
# would normally run this with per-account provider aliases or a separate
# workspace per account. The provider alias pattern is shown below — uncomment
# and extend as needed for your account count.
# ---------------------------------------------------------------------------

# Reuse the same monitoring policy document for member account roles.
# The policy is identical — member accounts only need workload monitoring
# permissions (organization-level actions like organizations:ListAccounts are
# not needed on member accounts).
resource "aws_iam_policy" "turbonomic_monitor_member" {
  for_each = toset(var.member_account_ids)

  name        = "${var.policy_name}-member-${each.key}"
  description = "Minimum read-only permissions for Turbonomic to monitor workloads in AWS member account ${each.key}."
  tags        = var.tags

  # Member accounts do not need the organizations:*, pricing:*, s3:*,
  # sts:AssumeRole, or ce:* management-only permissions.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "IAMIdentityCheck"
        Effect = "Allow"
        Action = ["iam:GetUser"]
        Resource = "*"
      },
      {
        Sid    = "RegionsAndZones"
        Effect = "Allow"
        Action = [
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeRegions"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "PerformanceInsights"
        Effect = "Allow"
        Action = [
          "pi:GetResourceMetrics",
          "pi:ListAvailableResourceMetrics"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2Discovery"
        Effect = "Allow"
        Action = [
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
          "ec2:DescribeReservedInstancesModifications"
        ]
        Resource = "*"
      },
      {
        Sid    = "AutoScalingDiscovery"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeTags",
          "autoscaling:DescribeLaunchConfigurations"
        ]
        Resource = "*"
      },
      {
        Sid    = "LaunchTemplateDiscovery"
        Effect = "Allow"
        Action = ["ec2:DescribeLaunchTemplateVersions"]
        Resource = "*"
      },
      {
        Sid    = "EKSDiscovery"
        Effect = "Allow"
        Action = [
          "eks:ListClusters",
          "eks:DescribeCluster",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Sid    = "EBSDiscovery"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumesModifications"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudTrailEBSHistory"
        Effect = "Allow"
        Action = ["cloudtrail:LookupEvents"]
        Resource = "*"
      },
      {
        Sid    = "RDSAndAuroraDiscovery"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "rds:DescribeDBParameters",
          "rds:DescribeOrderableDBInstanceOptions",
          "rds:DescribeReservedDBInstances",
          "rds:ListTagsForResource",
          "rds:DescribeGlobalClusters",
          "rds:DescribeBlueGreenDeployments"
        ]
        Resource = "*"
      },
      {
        Sid    = "RedshiftDiscovery"
        Effect = "Allow"
        Action = [
          "redshift:DescribeClusters",
          "redshift:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "SavingsAndReservations"
        Effect = "Allow"
        Action = [
          "savingsplans:DescribeSavingsPlans",
          "savingsplans:DescribeSavingsPlansOfferingRates"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "turbonomic_member" {
  for_each = toset(var.member_account_ids)

  name        = var.member_role_name
  description = "Assumed by Turbonomic (via the management account role) to monitor workloads in member account ${each.key}."
  tags        = var.tags

  # Trust the management account role, not the Turbonomic account directly.
  # This mirrors the AWS Organizations cross-account pattern.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TrustManagementAccountRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:role/${var.management_role_name}"
        }
        Action = "sts:AssumeRole"
        Condition = var.external_id != "" ? {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        } : {}
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "turbonomic_member" {
  for_each = toset(var.member_account_ids)

  role       = aws_iam_role.turbonomic_member[each.key].name
  policy_arn = aws_iam_policy.turbonomic_monitor_member[each.key].arn
}

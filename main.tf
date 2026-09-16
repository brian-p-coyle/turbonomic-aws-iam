terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Management account IAM policy — read-only workload monitoring
# Covers: Organizations, IAM, EC2, Auto Scaling, EKS, EBS, RDS, Aurora,
#         Redshift, CloudWatch, Performance Insights, Reserved Instances,
#         Savings Plans, Cost Explorer, Pricing, S3 (billing), CloudTrail
# ---------------------------------------------------------------------------
resource "aws_iam_policy" "turbonomic_monitor" {
  name        = var.policy_name
  description = "Minimum read-only permissions for Turbonomic to monitor AWS workloads (multi-account, management account)."
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "OrgDiscovery"
        Effect = "Allow"
        Action = [
          "organizations:DescribeOrganization",
          "organizations:ListAccounts",
          "organizations:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMAndSTS"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "sts:AssumeRole"
        ]
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
        Action = [
          "ec2:DescribeLaunchTemplateVersions"
        ]
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
        Action = [
          "cloudtrail:LookupEvents"
        ]
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
          "savingsplans:DescribeSavingsPlansOfferingRates",
          "ce:GetReservationUtilization",
          "ce:GetSavingsPlansUtilizationDetails"
        ]
        Resource = "*"
      },
      {
        Sid    = "PricingDiscovery"
        Effect = "Allow"
        Action = [
          "pricing:DescribeServices",
          "pricing:GetAttributeValues"
        ]
        Resource = "*"
      },
      {
        Sid    = "BillingS3Access"
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:GetObject"
        ]
        Resource = "*"
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Management account IAM role — trusted by the Turbonomic AWS account
# ---------------------------------------------------------------------------
resource "aws_iam_role" "turbonomic_management" {
  name        = var.management_role_name
  description = "Assumed by Turbonomic to monitor the Organizations management account and discover member accounts."
  tags        = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TurbonomicAssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.turbonomic_account_id}:root"
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

resource "aws_iam_role_policy_attachment" "turbonomic_management" {
  role       = aws_iam_role.turbonomic_management.name
  policy_arn = aws_iam_policy.turbonomic_monitor.arn
}

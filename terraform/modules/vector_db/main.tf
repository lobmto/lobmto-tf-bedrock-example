data "aws_caller_identity" "current" {}

locals {
  collection_name = "${var.project_name}-this"
  my_arn          = data.aws_caller_identity.current.arn
}

resource "aws_opensearchserverless_collection" "this" {
  name = local.collection_name
  type = "VECTORSEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network
  ]
}

resource "aws_opensearchserverless_security_policy" "encryption" {
  name = local.collection_name
  type = "encryption"
  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          "collection/${local.collection_name}"
        ],
        "ResourceType" = "collection"
      }
    ],
    "AWSOwnedKey" = true
  })
}

resource "aws_opensearchserverless_access_policy" "current_user" {
  name        = "${var.project_name}-${data.aws_caller_identity.current.account_id}"
  type        = "data"
  description = "read and write permissions"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index",
          Resource = [
            "index/${local.collection_name}/*"
          ],
          Permission = [
            "aoss:*"
          ]
        },
        {
          ResourceType = "collection",
          Resource = [
            "collection/${local.collection_name}"
          ],
          Permission = [
            "aoss:*"
          ]
        }
      ],
      Principal = [
        local.my_arn
      ]
    }
  ])
}

resource "aws_opensearchserverless_security_policy" "network" {
  name = "${var.project_name}-${data.aws_caller_identity.current.account_id}"
  type = "network"
  policy = jsonencode([
    {
      Description = "Public access to collection and Dashboards endpoint for example collection",
      Rules = [
        {
          ResourceType = "collection",
          Resource = [
            "collection/${local.collection_name}"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/${local.collection_name}"
          ]
        }
      ],
      AllowFromPublic = true
    }
  ])
}

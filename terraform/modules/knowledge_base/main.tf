data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_bedrock_foundation_model" "embedding" {
  model_id = "amazon.titan-embed-text-v1"
}

locals {
  account_id      = data.aws_caller_identity.current.account_id
  collection_name = "${var.project_name}-this"
}

resource "aws_s3_bucket" "knowledge_base" {
  bucket = "${var.project_name}-knowledge-base-${local.account_id}"

  tags = {
    Name = var.project_name
  }
}

resource "aws_bedrockagent_knowledge_base" "this" {
  name     = "${var.project_name}-knowledge-base"
  role_arn = aws_iam_role.bedrock.arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = data.aws_bedrock_foundation_model.embedding.model_arn
    }
    type = "VECTOR"
  }
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = var.vector_db.arn
      vector_index_name = var.vector_db.index_name
      field_mapping {
        vector_field   = var.vector_db.vector_field
        text_field     = var.vector_db.text_field
        metadata_field = var.vector_db.metadata_field
      }
    }
  }
}

data "aws_iam_policy_document" "bedrock_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bedrock" {
  name               = "${var.project_name}-bedrock"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.bedrock_assume_role.json
  managed_policy_arns = [
    aws_iam_policy.aoss.arn,
    aws_iam_policy.model.arn,
    aws_iam_policy.s3.arn
  ]
}

resource "aws_iam_policy" "aoss" {
  name   = "${var.project_name}-aoss"
  policy = data.aws_iam_policy_document.aoss.json
}
resource "aws_iam_policy" "model" {
  name   = "${var.project_name}-model"
  policy = data.aws_iam_policy_document.model.json
}
resource "aws_iam_policy" "s3" {
  name   = "${var.project_name}-s3"
  policy = data.aws_iam_policy_document.s3.json
}

data "aws_iam_policy_document" "aoss" {
  statement {
    sid = "1"
    actions = [
      "aoss:APIAccessAll"
    ]
    resources = [
      var.vector_db.arn
    ]
  }
}

data "aws_iam_policy_document" "model" {
  statement {
    sid = "2"
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = [
      "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1"
    ]
  }
}

data "aws_iam_policy_document" "s3" {
  statement {
    sid = "1"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.knowledge_base.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values = [
        "325848924379"
      ]
    }
  }
  statement {
    sid = "2"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.knowledge_base.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values = [
        "325848924379"
      ]
    }
  }
}

resource "awscc_bedrock_data_source" "this" {
  name              = var.project_name
  knowledge_base_id = aws_bedrockagent_knowledge_base.this.id
  data_source_configuration = {
    type = "S3"
    s3_configuration = {
      bucket_arn = aws_s3_bucket.knowledge_base.arn
    }
  }
}

// Permission は下記を参照
// https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-create.html
resource "aws_opensearchserverless_access_policy" "data" {
  name        = "${var.project_name}-bedrock"
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
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument",
            "aoss:CreateIndex"
          ]
          }, {
          ResourceType = "collection",
          Resource = [
            "collection/${local.collection_name}"
          ],
          Permission = [
            "aoss:DescribeCollectionItems",
            "aoss:CreateCollectionItems",
            "aoss:UpdateCollectionItems"
          ]
        }
      ],
      Principal = [
        aws_iam_role.bedrock.arn
      ]
    }
  ])
}

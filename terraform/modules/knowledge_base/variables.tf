variable "project_name" {
  type        = string
  description = "プロジェクトの名称。各種リソースのプレフィックス・タグに用いる。"
}

variable "vector_db" {
  type = object({
    arn            = string
    index_name     = optional(string, "default-index")
    vector_field   = optional(string, "default-vector")
    text_field     = optional(string, "AMAZON_BEDROCK_TEXT_CHUNK")
    metadata_field = optional(string, "AMAZON_BEDROCK_METADATA")
  })
  description = "ベクトルDBの設定値。"
}

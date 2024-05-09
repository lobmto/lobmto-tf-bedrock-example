### 1. 変数の設定
```bash
cp terraform.tfvars.example terraform.tfvars
# ファイル内の変数（プロジェクト名など）を適宜設定する
```

### 2. OpenSearch Serverless の構築
```bash
terraform apply -target=module.vector_db
```

### 3. OpenSearch Serverless の初期設定
AWS Management Console の `Amazon OpenSearch Service / Collections / indexes` にて、下記を設定する。

参考: [Set up a vector index for your knowledge base in a supported vector store](https://docs.aws.amazon.com/ja_jp/bedrock/latest/userguide/knowledge-base-setup.html)

**Vector index details**

| Vector index name |
| --- |
| default-index |

---

**Vector fields**

| Vector Field | Engine | Dimensions | 	Distance type|
| --- | --- | --- | ---|
| default-vector | faiss | 1536 | Euclidiean |

---

**Metadata management**

| Mapping field | Data type | Filterable |
| --- | --- | --- |
| AMAZON_BEDROCK_TEXT_CHUNK | String | True |
| AMAZON_BEDROCK_METADATA | String | False |

### 4. RAG の構築
```bash
terraform apply
# TODO: 途中で失敗することがあるが再施行すれば通る（依存関係の調査中）
```

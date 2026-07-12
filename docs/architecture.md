### Architecture
Reference Architecture

```
Angular UI
      |
      v
Spring Boot REST API
      |
      v
Spring AI
      |
 +------------------+
 |                  |
 v                  v
Amazon Bedrock   MCP Tools
 |                  |
 v                  v
Claude / Llama / Nova   SQL / REST APIs / Documents
      |
      v
Vector Database (Amazon OpenSearch, pgvector, or Pinecone)
      |
      v
Amazon RDS / DynamoDB
```
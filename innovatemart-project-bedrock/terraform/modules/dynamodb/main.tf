resource "aws_dynamodb_table" "carts" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    # Primary key expected by the carts service entity (@DynamoDbPartitionKey on getId)
    name = "id"
    type = "S"
  }

  # Attribute used by the application's GSI for lookups by customerId
  attribute {
    name = "customerId"
    type = "S"
  }

  # Match the entity's partition key attribute name
  hash_key = "id"

  # Global Secondary Index required by the carts service
  global_secondary_index {
    name               = "idx_global_customerId"
    hash_key           = "customerId"
    projection_type    = "ALL"
  }

  tags = {
    Name = "CartsTable"
  }
}
# ==========================================================
# Snowflake Terraform Accelerator - Full Infra (Single file)
# PARSER-FRIENDLY VERSION (for TF ZIP -> SQL app)
# - One attribute per line
# - Stage created before Pipe
# - Stream uses local table name (no DB.SCHEMA.TABLE)
# - Attachments use fully-qualified policy/table (FQN)
# ==========================================================

resource "snowflake_database" "db" {
  name = "TF_ACCEL_DB"
  comment = "Terraform Accelerator Database"
}

resource "snowflake_schema" "raw" {
  database = "TF_ACCEL_DB"
  name = "RAW"
  comment = "Raw zone"
}

resource "snowflake_schema" "curated" {
  database = "TF_ACCEL_DB"
  name = "CURATED"
  comment = "Curated zone"
}

resource "snowflake_schema" "app" {
  database = "TF_ACCEL_DB"
  name = "APP"
  comment = "App metadata zone"
}

resource "snowflake_warehouse" "wh" {
  name = "TF_ACCEL_WH"
  warehouse_size = "XSMALL"
  auto_suspend = 60
  auto_resume = true
  comment = "Warehouse for Terraform Accelerator"
}

resource "snowflake_role" "admin" {
  name = "TF_ACCEL_ADMIN"
  comment = "Admin role"
}

resource "snowflake_role" "dev" {
  name = "TF_ACCEL_DEV"
  comment = "Developer role"
}

resource "snowflake_role" "analyst" {
  name = "TF_ACCEL_ANALYST"
  comment = "Analyst role"
}

resource "snowflake_role_grants" "admin_inherits_dev" {
  role_name = "TF_ACCEL_ADMIN"
  roles = ["TF_ACCEL_DEV"]
}

resource "snowflake_role_grants" "dev_inherits_analyst" {
  role_name = "TF_ACCEL_DEV"
  roles = ["TF_ACCEL_ANALYST"]
}

resource "snowflake_user" "dev_user" {
  name = "TF_ACCEL_DEV_USER"
  login_name = "tf_accel_dev_user"
  email = "dev@example.com"
  default_role = "TF_ACCEL_DEV"
  comment = "Dev user"
}

resource "snowflake_user" "analyst_user" {
  name = "TF_ACCEL_ANALYST_USER"
  login_name = "tf_accel_analyst_user"
  email = "analyst@example.com"
  default_role = "TF_ACCEL_ANALYST"
  comment = "Analyst user"
}

resource "snowflake_role_grants" "grant_dev_user" {
  role_name = "TF_ACCEL_DEV"
  users = ["TF_ACCEL_DEV_USER"]
}

resource "snowflake_role_grants" "grant_analyst_user" {
  role_name = "TF_ACCEL_ANALYST"
  users = ["TF_ACCEL_ANALYST_USER"]
}

resource "snowflake_grant_privileges_to_role" "db_usage_admin" {
  role_name = "TF_ACCEL_ADMIN"
  privileges = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = "TF_ACCEL_DB"
  }
}

resource "snowflake_grant_privileges_to_role" "db_usage_dev" {
  role_name = "TF_ACCEL_DEV"
  privileges = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = "TF_ACCEL_DB"
  }
}

resource "snowflake_grant_privileges_to_role" "db_usage_analyst" {
  role_name = "TF_ACCEL_ANALYST"
  privileges = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = "TF_ACCEL_DB"
  }
}

resource "snowflake_grant_privileges_to_role" "raw_usage_analyst" {
  role_name = "TF_ACCEL_ANALYST"
  privileges = ["USAGE"]
  on_schema {
    schema_name = "TF_ACCEL_DB.RAW"
  }
}

resource "snowflake_grant_privileges_to_role" "curated_usage_analyst" {
  role_name = "TF_ACCEL_ANALYST"
  privileges = ["USAGE"]
  on_schema {
    schema_name = "TF_ACCEL_DB.CURATED"
  }
}

resource "snowflake_grant_privileges_to_role" "curated_dev_create" {
  role_name = "TF_ACCEL_DEV"
  privileges = ["USAGE", "CREATE TABLE", "CREATE VIEW"]
  on_schema {
    schema_name = "TF_ACCEL_DB.CURATED"
  }
}

resource "snowflake_grant_privileges_to_role" "app_usage_dev" {
  role_name = "TF_ACCEL_DEV"
  privileges = ["USAGE", "CREATE TABLE"]
  on_schema {
    schema_name = "TF_ACCEL_DB.APP"
  }
}

resource "snowflake_grant_privileges_to_role" "wh_usage_dev" {
  role_name = "TF_ACCEL_DEV"
  privileges = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = "TF_ACCEL_WH"
  }
}

resource "snowflake_grant_privileges_to_role" "wh_usage_analyst" {
  role_name = "TF_ACCEL_ANALYST"
  privileges = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = "TF_ACCEL_WH"
  }
}

resource "snowflake_grant_privileges_to_role" "wh_admin_full" {
  role_name = "TF_ACCEL_ADMIN"
  privileges = ["USAGE", "OPERATE", "MONITOR"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = "TF_ACCEL_WH"
  }
}

resource "snowflake_stage" "orders_stage" {
  database = "TF_ACCEL_DB"
  schema = "RAW"
  name = "ORDERS_STAGE"
  comment = "Internal stage for orders load"
}

resource "snowflake_table" "customer" {
  database = "TF_ACCEL_DB"
  schema = "CURATED"
  name = "CUSTOMER"
  column { name = "CUSTOMER_ID", type = "NUMBER(38,0)", nullable = false }
  column { name = "EMAIL", type = "VARCHAR", nullable = true }
  column { name = "REGION", type = "VARCHAR", nullable = true }
  column { name = "AMOUNT", type = "NUMBER(12,2)", nullable = true }
}

resource "snowflake_table" "orders" {
  database = "TF_ACCEL_DB"
  schema = "CURATED"
  name = "ORDERS"
  column { name = "ORDER_ID", type = "NUMBER(38,0)", nullable = false }
  column { name = "CUSTOMER_ID", type = "NUMBER(38,0)", nullable = false }
  column { name = "ORDER_TS", type = "TIMESTAMP_NTZ", nullable = true }
  column { name = "STATUS", type = "VARCHAR", nullable = true }
  column { name = "TOTAL", type = "NUMBER(12,2)", nullable = true }
}

resource "snowflake_view" "v_customer_spend" {
  database = "TF_ACCEL_DB"
  schema = "CURATED"
  name = "V_CUSTOMER_SPEND"
  statement = <<SQL
SELECT
  c.customer_id,
  c.region,
  SUM(o.total) AS total_spend
FROM TF_ACCEL_DB.CURATED.CUSTOMER c
JOIN TF_ACCEL_DB.CURATED.ORDERS o
  ON c.customer_id = o.customer_id
GROUP BY 1,2
SQL
}

# ✅ FIX: avoid FQN here (your parser used to reject dots)
resource "snowflake_stream" "orders_stream" {
  database = "TF_ACCEL_DB"
  schema = "CURATED"
  name = "ORDERS_STREAM"
  on_table = "ORDERS"
  comment = "Track changes on ORDERS"
}

resource "snowflake_task" "daily_agg" {
  database = "TF_ACCEL_DB"
  schema = "CURATED"
  name = "TASK_DAILY_AGG"
  warehouse = "TF_ACCEL_WH"
  schedule = "USING CRON 0 2 * * * UTC"
  sql_statement = <<SQL
CREATE OR REPLACE TABLE TF_ACCEL_DB.CURATED.DAILY_SALES_AGG AS
SELECT
  DATE_TRUNC('DAY', ORDER_TS) AS sales_day,
  COUNT(*) AS orders_cnt,
  SUM(TOTAL) AS total_sales
FROM TF_ACCEL_DB.CURATED.ORDERS
GROUP BY 1;
SQL
  comment = "Daily aggregation task"
}

resource "snowflake_pipe" "orders_pipe" {
  database = "TF_ACCEL_DB"
  schema = "RAW"
  name = "PIPE_ORDERS"
  comment = "Template Snowpipe using internal stage"
  copy_statement = <<SQL
COPY INTO TF_ACCEL_DB.CURATED.ORDERS
FROM @TF_ACCEL_DB.RAW.ORDERS_STAGE
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY='\"' SKIP_HEADER=1)
ON_ERROR = 'CONTINUE';
SQL
}

resource "snowflake_masking_policy" "mask_email" {
  database = "TF_ACCEL_DB"
  schema = "CURATED"
  name = "MP_MASK_EMAIL"
  signature {
    column {
      name = "VAL"
      type = "VARCHAR"
    }
  }
  masking_expression = <<SQL
CASE
  WHEN CURRENT_ROLE() = 'TF_ACCEL_ADMIN' THEN VAL
  ELSE '***MASKED***'
END
SQL
  comment = "Mask customer email for non-admin roles"
}

# ✅ keep FQN (Terraform-style); parser will be fixed below
resource "snowflake_masking_policy_attachment" "attach_mask_email" {
  masking_policy = "TF_ACCEL_DB.CURATED.MP_MASK_EMAIL"
  table = "TF_ACCEL_DB.CURATED.CUSTOMER"
  column = "EMAIL"
}

resource "snowflake_table" "user_region_access" {
  database = "TF_ACCEL_DB"
  schema = "APP"
  name = "USER_REGION_ACCESS"
  column { name = "USER_NAME", type = "VARCHAR", nullable = false }
  column { name = "REGION", type = "VARCHAR", nullable = false }
}

resource "snowflake_row_access_policy" "rap_region" {
  database = "TF_ACCEL_DB"
  schema = "CURATED"
  name = "RAP_BY_REGION"
  signature {
    column {
      name = "REGION"
      type = "VARCHAR"
    }
  }
  row_access_expression = <<SQL
CASE
  WHEN CURRENT_ROLE() = 'TF_ACCEL_ADMIN' THEN TRUE
  ELSE EXISTS (
    SELECT 1
    FROM TF_ACCEL_DB.APP.USER_REGION_ACCESS ura
    WHERE ura.USER_NAME = CURRENT_USER()
      AND ura.REGION = REGION
  )
END
SQL
  comment = "Filter rows by REGION using USER_REGION_ACCESS table"
}

# ✅ keep FQN (Terraform-style); parser will be fixed below
resource "snowflake_row_access_policy_attachment" "attach_rap_region" {
  row_access_policy = "TF_ACCEL_DB.CURATED.RAP_BY_REGION"
  table = "TF_ACCEL_DB.CURATED.CUSTOMER"
  column = "REGION"
}

output "database" {
  value = "TF_ACCEL_DB"
}

output "warehouse" {
  value = "TF_ACCEL_WH"
}

output "schemas" {
  value = ["RAW", "CURATED", "APP"]
}
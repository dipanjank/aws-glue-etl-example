import logging
import sys
from datetime import date
from random import choice

from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from pyspark.sql import DataFrame
from pyspark.sql import Row
from pyspark.sql import SparkSession


def main():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    spark_session = SparkSession.builder \
        .appName("WriteProducts") \
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
        .getOrCreate()

    glueContext = GlueContext(spark_session.sparkContext)
    logger = glueContext.get_logger()

    args = getResolvedOptions(
        sys.argv,
        [
            'JOB_NAME',
            'db_name',
            'product_table_name',
            'sales_table_name',
        ]
    )

    database_name = args['db_name']
    product_table_name = args['product_table_name']
    sales_table_name = args['sales_table_name']

    products_df = get_products(spark_session)
    update_table(products_df, database_name, product_table_name)
    logger.info("Updated products Delta table successfully.")

    sales_df = get_sales(spark_session)
    update_table(sales_df, database_name, sales_table_name)
    logger.info("Updated sales Delta table successfully.")


def update_table(table_df: DataFrame, database_name: str, table_name: str) -> None:
    # client = boto3.client("glue")
    # response = client.get_table(DatabaseName=database_name, Name=table_name)
    # s3_target_location = response["Table"]["StorageDescriptor"]["Location"]
    table_df.write.format("delta").mode("overwrite").saveAsTable(f"{database_name}.{table_name}")


def get_products(spark_session: SparkSession) -> DataFrame:
    data = [
        Row(product_id="P001", name="Laptop", category="Electronics"),
        Row(product_id="P002", name="Phone", category="Electronics"),
        Row(product_id="P003", name="Shirt", category="Clothing"),
        Row(product_id="P004", name="Shoes", category="Footwear"),
    ]
    products_df = spark_session.createDataFrame(data)
    return products_df


def get_sales(spark_session: SparkSession) -> DataFrame:
    rows = []

    for i in range(1, 1001):
        sales_id = str(i)
        product_id = choice(["P001", "P002", "P003", "P004"])
        quantity = choice([1, 2, 3, 4, 5])
        sale_date = choice(
            [
                date(2025, 1, 1),
                date(2025, 1, 2),
                date(2025, 1, 3),
                date(2025, 1, 4),
                date(2025, 1, 5),
            ]
        )
        rows.append(
            Row(sales_id=sales_id, product_id=product_id, quantity=quantity, sale_date=sale_date)
        )

    return spark_session.createDataFrame(rows)


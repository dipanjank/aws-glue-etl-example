import logging
import sys
from datetime import date
from random import choice

import boto3
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from pyspark.sql import DataFrame
from pyspark.sql import functions as F
from pyspark.sql import SparkSession


def main():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    spark_session = SparkSession.builder \
        .appName("DailySales") \
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
            'daily_summary_table_name',
        ]
    )
    database_name = args['db_name']
    product_table_name = args['product_table_name']
    sales_table_name = args['sales_table_name']
    summary_table_name = args['daily_summary_table_name']

    sales_df = get_data_from_table(spark_session, database_name, sales_table_name)
    products_df = get_data_from_table(spark_session, database_name, product_table_name)
    summary_df = daily_sales_by_category(products_df, sales_table_name)
    update_table(summary_df, database_name, summary_table_name)


def get_data_from_table(spark_session: SparkSession, database_name: str, sales_table_name: str) -> DataFrame:
    pass

def update_table(table_df: DataFrame, database_name: str, table_name: str) -> None:
    client = boto3.client("glue")
    response = client.get_table(DatabaseName=database_name, Name=table_name)
    s3_target_location = response["Table"]["StorageDescriptor"]["Location"]
    table_df.write.format("delta").mode("overwrite").save(s3_target_location)


def daily_sales_by_category(products_df: DataFrame, sales_df: DataFrame) -> DataFrame:
    return sales_df.join(
        products_df, on='product_id', how='inner'
    ).groupby(
        "sales_date", "category"
    ).agg(
        F.sum("quantity").alias("total_quantity"),
    )


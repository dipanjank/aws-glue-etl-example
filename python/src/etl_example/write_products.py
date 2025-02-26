import logging
import sys

import boto3
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from pyspark.sql import DataFrame
from pyspark.sql import SparkSession
from pyspark.sql import types as T


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
           'table_name',
        ]
    )

    database_name = args['db_name']
    table_name = args['table_name']

    # Sample data
    products_df = get_products(spark_session)

    # Get the S3 storage location from the Glue Data Catalog
    client = boto3.client("glue")
    response = client.get_table(DatabaseName=database_name, Name=table_name)
    s3_target_location = response["Table"]["StorageDescriptor"]["Location"]

    # Write data to Delta table (S3 location)
    products_df.write.format("delta").mode("overwrite").save(s3_target_location)
    logger.info("Updated products Delta table successfully.")


def get_products(spark_session: SparkSession) -> DataFrame:
    data = [
        ("P001", "Laptop", "Electronics"),
        ("P002", "Phone", "Electronics"),
        ("P003", "Shirt", "Clothing"),
        ("P004", "Shoes", "Footwear"),
    ]
    # Convert to Spark DataFrame
    products_df = spark_session.createDataFrame(
        data,
        schema=T.StructType(
            [
                T.StructField("product_id", T.StringType(), True),
                T.StructField("name", T.StringType(), True),
                T.StructField("category", T.StringType(), True),
            ]
        )
    )
    return products_df

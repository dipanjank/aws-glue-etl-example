import sys

import boto3
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from pyspark import SparkConf
from pyspark import SparkContext
from pyspark.sql import DataFrame
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def main():
    args = getResolvedOptions(
        sys.argv,
        [
            'JOB_NAME',
            'db_name',
            'product_table_name',
            'sales_table_name',
        ]
    )

    conf_list = [
        ("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog"),
        ("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
    ]
    spark_conf = SparkConf().setAll(conf_list)
    sc = SparkContext.getOrCreate(spark_conf)
    glue_context = GlueContext(sc)

    logger = glue_context.get_logger()
    spark_session = glue_context.spark_session

    database_name = args['db_name']
    product_table_name = args['product_table_name']
    sales_table_name = args['sales_table_name']
    summary_table_name = args['daily_summary_table_name']

    sales_df = get_data_from_table(spark_session, database_name, sales_table_name)
    products_df = get_data_from_table(spark_session, database_name, product_table_name)
    summary_df = daily_sales_by_category(products_df, sales_df)
    update_table(summary_df, database_name, summary_table_name)
    logger.info("Successfully updated daily sales table.")


def get_data_from_table(spark_session: SparkSession, database_name: str, table_name: str) -> DataFrame:
    return spark_session.read.format("delta").table(f"{database_name}.{table_name}")


def update_table(table_df: DataFrame, database_name: str, table_name: str) -> None:
    glue_client = boto3.client('glue')
    response = glue_client.get_table(DatabaseName=database_name, Name=table_name)
    external_location = response["Table"]['StorageDescriptor']['Location']
    table_df.write.format("delta").mode("overwrite").save(external_location)


def daily_sales_by_category(products_df: DataFrame, sales_df: DataFrame) -> DataFrame:
    return sales_df.join(
        products_df, on='product_id', how='inner'
    ).groupby(
        "sale_date", "category"
    ).agg(
        F.sum("quantity").alias("total_quantity"),
    )


if __name__ == '__main__':
    main()
import logging
import sys
from datetime import date
from random import choice

from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from pyspark import SparkConf
from pyspark import SparkContext
from pyspark.sql import DataFrame
from pyspark.sql import Row
from pyspark.sql import SparkSession


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

    # List all tables in the current database
    catalogs = spark_session.catalog.listCatalogs()
    logger.warn(f"************** Catalogs: {catalogs} ***********************")

    database_name = args['db_name']
    product_table_name = args['product_table_name']
    sales_table_name = args['sales_table_name']

    products_df = get_products(spark_session)
    update_table(products_df, database_name, product_table_name)
    logging.info("Updated products Delta table successfully.")

    # sales_df = get_sales(spark_session)
    # update_table(sales_df, database_name, sales_table_name)
    # logging.info("Updated sales Delta table successfully.")


def update_table(table_df: DataFrame, database_name: str, table_name: str) -> None:
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


if __name__ == '__main__':
    main()
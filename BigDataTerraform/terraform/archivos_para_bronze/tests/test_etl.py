import pytest
from pyspark.sql import SparkSession
import sys
from unittest.mock import MagicMock

# Mock del módulo awsglue
sys.modules['awsglue'] = MagicMock()
sys.modules['awsglue.utils'] = MagicMock()

from scripts.etl_sales import transform


@pytest.fixture(scope="session")
def spark():
    return SparkSession.builder \
        .master("local[*]") \
        .appName("test") \
        .getOrCreate()


def test_transform_schema(spark):
    # Asegúrate de simular la columna "datos" con el tipo de dato que espera tu script
    data = [
        ("1", "101", "laptop", "1200", "Bogota", "2024-01-01", ["un_dato_de_ejemplo"])
    ]
    
    # Sumamos "datos" al final para que la función pueda hacer el explode()
    columns = ["order_id", "customer_id", "product", "amount", "city", "date", "datos"]
    
    df = spark.createDataFrame(data, columns)
    result = transform(df)
    
    # Tus asserts...
    assert "dato" in result.columns


def test_transform_values(spark):
    data = [
        ("1", "101", "laptop", "1200", "Bogota", "2024-01-01")
    ]

    columns = ["order_id", "customer_id", "product", "amount", "city", "date"]

    df = spark.createDataFrame(data, columns)

    result = transform(df)

    row = result.collect()[0]

    assert row["order_id"] == 1
    assert row["amount"] == 1200.0
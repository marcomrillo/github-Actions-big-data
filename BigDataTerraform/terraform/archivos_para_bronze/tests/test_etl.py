import pytest
from pyspark.sql import SparkSession
from scripts.etl_sales import transform

@pytest.fixture(scope="module")
def spark():
    return SparkSession.builder \
        .appName("Testing PySpark local") \
        .master("local[*]") \
        .getOrCreate()

def test_transform_schema(spark):
    # Pasamos una lista de strings simulando lo que va a explotar el script
    data = [
        ("1", "101", "laptop", "1200", "Bogota", "2024-01-01", ["item1", "item2"])
    ]
    
    # IMPORTANTE: "datos" DEBE estar aquí listado al final
    columns = ["order_id", "customer_id", "product", "amount", "city", "date", "datos"]
    
    df = spark.createDataFrame(data, columns)
    result = transform(df)
    
    assert "dato" in result.columns

def test_transform_values(spark):
    data = [
        ("1", "101", "laptop", "1200", "Bogota", "2024-01-01", ["item1"])
    ]
    
    # IMPORTANTE: Aquí también sumamos "datos"
    columns = ["order_id", "customer_id", "product", "amount", "city", "date", "datos"]
    
    df = spark.createDataFrame(data, columns)
    result = transform(df)
    
    assert result.count() > 0
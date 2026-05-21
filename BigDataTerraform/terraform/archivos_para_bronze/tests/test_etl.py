import sys
from unittest.mock import MagicMock

# ====================================================================
# TRUCO MOCK: Simulamos la librería de AWS Glue antes de importar el script
# ====================================================================
class MockAwsGlueUtils:
    @staticmethod
    def getResolvedOptions(args, options):
        # Retorna un diccionario simulado con los argumentos que pida tu script
        return {"JOB_NAME": "test_glue_job"}

# Creamos módulos falsos en el sistema de Python
sys.modules['awsglue'] = MagicMock()
sys.modules['awsglue.utils'] = MockAwsGlueUtils
sys.modules['awsglue.context'] = MagicMock()
sys.modules['awsglue.job'] = MagicMock()

# ====================================================================
# AHORA SÍ PROSEGUIMOS CON LOS IMPORTS Y TESTS NORMALES
# ====================================================================
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
    data = [
        ("1", "101", "laptop", "1200", "Bogota", "2024-01-01", ["item1", "item2"])
    ]
    columns = ["order_id", "customer_id", "product", "amount", "city", "date", "datos"]
    
    df = spark.createDataFrame(data, columns)
    result = transform(df)
    
    assert "dato" in result.columns

def test_transform_values(spark):
    data = [
        ("1", "101", "laptop", "1200", "Bogota", "2024-01-01", ["item1"])
    ]
    columns = ["order_id", "customer_id", "product", "amount", "city", "date", "datos"]
    
    df = spark.createDataFrame(data, columns)
    result = transform(df)
    
    assert result.count() > 0
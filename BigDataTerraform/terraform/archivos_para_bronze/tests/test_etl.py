import sys
from unittest.mock import MagicMock

# Ajustamos el Mock para que soporte los 3 argumentos del nuevo Data Lake multinivel
class MockAwsGlueUtils:
    @staticmethod
    def getResolvedOptions(args, options):
        return {
            "input_path": "fake_bronze_path", 
            "silver_path": "fake_silver_path", 
            "gold_path": "fake_gold_path"
        }

sys.modules['awsglue'] = MagicMock()
sys.modules['awsglue.utils'] = MockAwsGlueUtils

import pytest
from pyspark.sql import SparkSession
from pyspark.sql.types import (
    StructType, StructField, StringType,
    DoubleType, ArrayType
)
from archivos_para_bronze.scripts.etl_air_quality import transform

@pytest.fixture(scope="module")
def spark():
    return SparkSession.builder \
        .appName("Testing PySpark local") \
        .master("local[*]") \
        .getOrCreate()

# Schema explícito que coincide exactamente con lo que el ETL espera
DATO_SCHEMA = StructType([
    StructField("fecha",             StringType(), True),
    StructField("variableConsulta",  StringType(), True),
    StructField("calidad",           StringType(), True),
    StructField("valor",             DoubleType(), True),
])

SCHEMA = StructType([
    StructField("nombre",       StringType(), True),
    StructField("nombreShorto", StringType(), True),
    StructField("latitud",      DoubleType(), True),
    StructField("longitud",     DoubleType(), True),
    StructField("datos",        ArrayType(DATO_SCHEMA), True),
])

def test_transform_schema(spark):
    data = [
        (
            "Estacion Central", "EC01", 4.65, -74.05,
            [
                ("2026-05-21 10:00:00", "PM2.5", "1", 25.5),
                ("2026-05-21 11:00:00", "PM2.5", "1", 30.2)
            ]
        )
    ]

    df = spark.createDataFrame(data, SCHEMA)
    result = transform(df)

    assert "estacion"         in result.columns
    assert "codigo_estacion"  in result.columns
    assert "fecha"            in result.columns
    assert "valor"            in result.columns

def test_transform_filters_invalid_values(spark):
    data = [
        (
            "Estacion Norte", "EN02", 4.70, -74.10,
            [
                ("2026-05-21 12:00:00", "PM2.5", "1", 250.0),  # Válido
                ("2026-05-21 13:00:00", "PM2.5", "1", -10.0),  # Inválido (Menor a 0)
                ("2026-05-21 14:00:00", "PM2.5", "1", 600.0)   # Inválido (Mayor a 500)
            ]
        )
    ]

    df = spark.createDataFrame(data, SCHEMA)
    result = transform(df)

    # El filtro de negocio (0-500) debe dejar únicamente 1 fila de las 3 ingresadas
    assert result.count() == 1
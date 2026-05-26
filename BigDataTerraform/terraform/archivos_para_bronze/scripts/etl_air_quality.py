import sys
from awsglue.utils import getResolvedOptions
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, explode, to_timestamp, avg, to_date

def transform(df):
    # 1. Explode del array datos
    df_exploded = df.withColumn("dato", explode("datos"))
    
    # 2. Flatten del JSON y casteo de tipos
    df_flat = df_exploded.select(
        col("nombre").alias("estacion"),
        col("nombreShorto").alias("codigo_estacion"),
        col("latitud").cast("double"),
        col("longitud").cast("double"),
        to_timestamp(col("dato.fecha")).alias("fecha"),
        col("dato.variableConsulta").alias("variable"),
        col("dato.calidad").cast("int").alias("calidad"),
        col("dato.valor").cast("double").alias("valor")
    )
    
    # 3. Limpieza básica optimizada
    df_clean = df_flat.dropna(subset=["fecha", "valor"])
    df_clean = df_clean.dropDuplicates(subset=["codigo_estacion", "fecha", "variable"])
    
    # 4. Filtro de negocio (Evita anomalías de sensores)
    df_final = df_clean.filter(
        (col("valor") >= 0) & (col("valor") <= 500)
    )
    
    return df_final

def main():
    # Añadimos los tres paths dinámicos para el Data Lake multinivel
    args = getResolvedOptions(sys.argv, ['input_path', 'silver_path', 'gold_path'])
    spark = SparkSession.builder.getOrCreate()

    # ---- CAPA BRONZE -> SILVER ----
    df = spark.read.option("multiline", "true").json(args['input_path'])
    df_silver = transform(df)

    # Escribir datos limpios y detallados en Silver (Particionados por estación)
    df_silver.write \
        .mode("overwrite") \
        .partitionBy("codigo_estacion") \
        .parquet(args['silver_path'])

    # ---- CAPA SILVER -> GOLD (Agregaciones para Dashboard) ----
    # Agrupamos por fecha (día), estación y variable para calcular promedios diarios
    df_gold = df_silver.groupBy(
        "estacion", 
        "codigo_estacion", 
        "latitud", 
        "longitud", 
        to_date("fecha").alias("fecha_dia"), 
        "variable"
    ).agg(
        avg("valor").alias("promedio_valor"),
        avg("calidad").cast("int").alias("promedio_calidad")
    )

    # Escribir datos agregados de alto rendimiento en Gold
    df_gold.write \
        .mode("overwrite") \
        .partitionBy("codigo_estacion") \
        .parquet(args['gold_path'])

if __name__ == "__main__":
    main()
import sys
from awsglue.utils import getResolvedOptions
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, explode, to_timestamp

def transform(df):
    # 1. Explode del array datos
    df_exploded = df.withColumn("dato", explode("datos"))
    
    # 2. Flatten del JSON y casteo de tipos
    df_flat = df_exploded.select(
        col("nombre").alias("estacion"),
        col("nombreCorto").alias("codigo_estacion"),
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
    
    # 4. Filtro de negocio
    df_final = df_clean.filter(
        (col("valor") >= 0) & (col("valor") <= 500)
    )
    
    return df_final

def main():
    # Recibe las rutas dinámicamente desde AWS Glue / Terraform
    args = getResolvedOptions(sys.argv, ['input_path', 'output_path'])

    spark = SparkSession.builder.getOrCreate()

    # Cambiado a JSON multiline para tus datos reales
    df = spark.read.option("multiline", "true").json(args['input_path'])

    df_transformed = transform(df)

    # Guarda particionando eficientemente por estación
    df_transformed.write \
        .mode("overwrite") \
        .partitionBy("codigo_estacion") \
        .parquet(args['output_path'])

if __name__ == "__main__":
    main()
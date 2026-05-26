import sys
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql.functions import col, avg, when, to_date, round

def transform_gold(df):
    # 1. Crear fecha diaria a partir del timestamp de Silver
    df_with_date = df.withColumn("fecha_dia", to_date(col("fecha")))

    # 2. Agrupar métricas por fecha y estación para calcular el promedio diario
    df_grouped = df_with_date.groupBy("fecha_dia", "estacion").agg(
        round(avg("valor"), 2).alias("promedio_pm25")
    )

    # 3. Clasificación de categoría según la norma de calidad del aire
    df_final = df_grouped.withColumn(
        "categoria_aire",
        when(col("promedio_pm25") <= 12, "Buena")
        .when((col("promedio_pm25") > 12) & (col("promedio_pm25") <= 35), "Moderada")
        .otherwise("Mala")
    )
    
    return df_final

def main():
    # Recibimos las rutas dinámicas enviadas por Terraform
    args = getResolvedOptions(sys.argv, ['silver_path', 'gold_path'])
    
    # Inicialización del ecosistema de Glue/Spark
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)

    # ---- PROCESAMIENTO SILVER TO GOLD ----
    # Leer datos limpios en formato Parquet desde la capa Silver
    df_silver = spark.read.parquet(args['silver_path'])
    
    # Aplicar las reglas analíticas de negocio
    df_gold = transform_gold(df_silver)

    # Guardar el resultado final en la capa Gold para consumo analítico
    df_gold.write \
        .mode("overwrite") \
        .parquet(args['gold_path'])

    job.commit()

if __name__ == "__main__":
    main()
import sys
from awsglue.utils import getResolvedOptions
from pyspark.sql import SparkSession
import great_expectations as gx

def main():
    args = getResolvedOptions(sys.argv, ['input_path'])
    spark = SparkSession.builder.getOrCreate()
    
    # 1. Leer el JSON crudo de Bronze
    df = spark.read.option("multiline", "true").json(args['input_path'])
    
    # 2. Inicializar Great Expectations en memoria
    context = gx.get_context()
    datasource = context.sources.add_spark("siata_source", dataframe=df)
    asset = datasource.add_dataframe_asset("siata_asset")
    
    # 3. Definir las reglas de validación estructural
    suite = context.add_expectation_suite("siata_quality_suite")
    
    asset.add_expectation_column_to_exist("nombre")
    asset.add_expectation_column_to_exist("nombreShorto")
    asset.add_expectation_column_to_exist("latitud")
    asset.add_expectation_column_to_exist("longitud")
    asset.add_expectation_column_to_exist("datos") 
    
    # 4. Ejecutar el control de calidad
    checkpoint = context.add_checkpoint(
        name="quality_gatekeeper",
        expectation_suite=suite,
        asset=asset
    )
    validation_result = checkpoint.run()
    
    # 5. Si falla, rompe el Job para que la Step Function se entere
    if not validation_result["success"]:
        raise ValueError("CRITICAL_DATA_QUALITY_FAIL: El archivo JSON no cumple con los estándares.")
        
    print("SUCCESS: Validación de Great Expectations aprobada.")

if __name__ == "__main__":
    main()
import sys
from awsglue.utils import getResolvedOptions
from pyspark.sql import SparkSession
import great_expectations as gx


def main():
    args = getResolvedOptions(sys.argv, ['input_path'])
    spark = SparkSession.builder.getOrCreate()

    # 1. Leer el JSON crudo de Bronze
    df = spark.read.option("multiline", "true").json(args['input_path'])

    # 2. Contexto efímero de GX (en memoria, sin persistencia en disco)
    context = gx.get_context()

    # 3. Datasource Spark + asset de dataframe (API fluida de GX 0.18)
    datasource = context.sources.add_or_update_spark("siata_source")
    asset = datasource.add_dataframe_asset(name="siata_asset")

    # 4. Batch request: el dataframe se entrega en runtime, no al crear el asset
    batch_request = asset.build_batch_request(dataframe=df)

    # 5. Suite de expectativas
    suite_name = "siata_quality_suite"
    context.add_or_update_expectation_suite(suite_name)

    # 6. Validator + reglas de validación estructural
    validator = context.get_validator(
        batch_request=batch_request,
        expectation_suite_name=suite_name,
    )
    for column in ["nombre", "nombreCorto", "latitud", "longitud", "datos"]:
        validator.expect_column_to_exist(column)
    validator.save_expectation_suite(discard_failed_expectations=False)

    # 7. Checkpoint que ejecuta el control de calidad sobre el batch
    checkpoint = context.add_or_update_checkpoint(
        name="quality_gatekeeper",
        validator=validator,
    )
    result = checkpoint.run()

    # 8. Si falla, rompe el Job para que la Step Function se entere
    if not result["success"]:
        raise ValueError(
            "CRITICAL_DATA_QUALITY_FAIL: El archivo JSON no cumple con los estándares."
        )

    print("SUCCESS: Validación de Great Expectations aprobada.")


if __name__ == "__main__":
    main()

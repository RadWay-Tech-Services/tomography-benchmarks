import argparse
import configparser


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--pipeline", required=True)
    parser.add_argument("--input-file", required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--gpus", required=True)
    args = parser.parse_args()

    config = configparser.ConfigParser()

    with open(args.pipeline, "r") as pipeline_file:
        config.read_file(pipeline_file)

    config["dataset"]["location"] = args.input_file
    config["output"]["location"] = args.output_dir
    config["resources"]["gpus"] = args.gpus
    config["resources"]["workers"] = args.gpus

    with open(args.pipeline + ".tmp", "w") as tmp_pipeline_file:
        config.write(tmp_pipeline_file)


if __name__ == "__main__":
    main()

default-env-name := "tomobenchmarks"
default-detector-width := "1024"
default-projection-count := "512"
default-detector-height := "1024"

create-conda-env env-name=default-env-name:
    conda env create --yes --name {{env-name}} --file environment.yml
    conda run --no-capture-output --name {{env-name}} -- pip install git+https://github.com/lebedov/scikit-cuda@0.5.1 nabu[full]==2025.2.6 \
        git+https://github.com/tomography/tomocupy@v1.1.0 \
        tomobar==2026.3.1.0 httomolib==4.2 httomolibgpu==5.7 httomo-backends==1.2.0 \
        httomo==3.2.1

generate-input-data env-name=default-env-name detector-width=default-detector-width detector-height=default-detector-height projection-count=default-projection-count:
    conda run --no-capture-output --name {{env-name}} -- python scripts/nxs_generator.py --output-path synthetic.nx --sinogram-shape {{detector-height}} {{projection-count}} {{detector-width}}


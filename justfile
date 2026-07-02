create-conda-env env-name='tomobenchmarks':
    conda env create --yes --name {{env-name}} --file environment.yml
    conda run --no-capture-output --name {{env-name}} -- pip install git+https://github.com/lebedov/scikit-cuda@0.5.1 nabu[full]==2025.2.6 \
        git+https://github.com/tomography/tomocupy@v1.1.0 \
        tomobar==2026.3.1.0 httomolib==4.2 httomolibgpu==5.7 httomo-backends==1.2.0 \
        httomo==3.2.1

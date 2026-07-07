env-name := "tomobenchmarks"

default: recreate-env generate-input run-all

# Recreate environment.yml
export-env: delete-env
    # Base
    conda create --yes --name {{env-name}} --channel main --channel conda-forge --channel httomo python=3.12 pip wheel openmpi==4.1.6 h5py[build=*openmpi*] numpy=2.4 cuda-version=12.9 cuda cupy=14.0 gcc=14 gxx=14 main::sysroot_linux-64 tomophantom
    # httomo dependencies
    conda install --yes --name {{env-name}} --channel conda-forge astra-toolbox aiofiles click graypy loguru nvtx pillow pyyaml scikit-image scipy tqdm hdf5plugin pywavelets
    # Nabu dependencies
    conda install --yes --name {{env-name}} --channel conda-forge matplotlib silx ipython notebook ipympl pyqt pycuda pyopencl pyvkfft cuda-nvvm
    # TomoCuPy dependencies
    conda install --yes --name {{env-name}} --channel conda-forge scikit-build swig numexpr tifffile cmake
    # Export
    conda export --name {{env-name}} --file environment.yml

# Create Conda env from environment.yml and installs packages via Pip
recreate-env: delete-env && pip-install
    conda env create --yes --name {{env-name}} --file environment.yml

# Delete Conda env
delete-env:
    -conda env remove --yes --name {{env-name}}

# Installs required packages from PyPi
pip-install:
    conda run --no-capture-output --name {{env-name}} -- pip install \
        git+https://github.com/lebedov/scikit-cuda@0.5.1 \
        nabu[full]==2025.2.6 \
        git+https://github.com/tomography/tomocupy@v1.1.0 \
        tomobar==2026.3.1.0 \
        httomolib==4.2 \
        httomolibgpu==5.7 \
        httomo-backends==1.2.0 \
        httomo==3.2.1

# Creates synthetic Nexus file using tomophantom
generate-input detector-width="1024" detector-height="1024" projection-count="512":
    conda run --no-capture-output --name {{env-name}} -- python scripts/nxs_generator.py --output-path synthetic.nx --sinogram-shape {{detector-height}} {{projection-count}} {{detector-width}}

run-all: \
    (run-httomo "pipelines/httomo/fbp-preproc.yaml") \
    (run-httomo "pipelines/httomo/fbp.yaml") \
    (run-httomo "pipelines/httomo/lprec.yaml") \
    (run-nabu "pipelines/nabu/fbp-preproc.conf") \
    (run-nabu "pipelines/nabu/fbp.conf") \
    (run-tomocupy "pipelines/tomocupy/fbp-preproc.conf") \
    (run-tomocupy "pipelines/tomocupy/fbp.conf") \
    (run-tomocupy "pipelines/tomocupy/lprec.conf")

# Run httomo tomography pipeline
run-httomo pipeline nodes="1":
    conda run --no-capture-output --name {{env-name}} -- mpirun -n {{nodes}} bash -c "time python -m httomo run synthetic.nx {{pipeline}} httomo-out"

# Run Nabu tomography pipeline
run-nabu pipeline:
    mkdir -p nabu-out
    conda run --no-capture-output --name {{env-name}} -- bash -c 'PATH=$CONDA_PREFIX/nvvm/bin:$PATH time nabu {{pipeline}}'

# Run tomocupy tomography pipeline
run-tomocupy pipeline:
    conda run --no-capture-output --name {{env-name}} -- time tomocupy recon --config {{pipeline}} --out-path-name tomocupy-out --save-format h5nolinks

# Removes all non-version controlled files in the directory
cleanup:
    git clean -fdx

env-name := "tomobenchmarks"
default-nx := "synthetic.nx"

default: recreate-env generate-input run-all

# Recreate environment.yml
export-env: delete-env
    # Base
    conda create --yes --name {{env-name}} --channel main --channel conda-forge --channel httomo python=3.12 pip wheel openmpi==4.1.6 h5py[build=*openmpi*] numpy=2.4 cuda-version=12.9 cuda cupy=14.0 gcc=14 gxx=14 main::sysroot_linux-64
    # httomo dependencies
    conda install --yes --name {{env-name}} --channel conda-forge astra-toolbox aiofiles click graypy loguru nvtx pillow pyyaml scikit-image scipy tqdm hdf5plugin pywavelets
    # Nabu dependencies
    conda install --yes --name {{env-name}} --channel conda-forge matplotlib silx ipython notebook ipympl pyqt pycuda pyopencl pyvkfft cuda-nvvm
    # TomoCuPy dependencies
    conda install --yes --name {{env-name}} --channel conda-forge scikit-build swig numexpr tifffile cmake
    # Export
    conda export --name {{env-name}} --file environment.yml

# Create Conda env from environment.yml and installs packages via Pip
recreate-env: delete-env && pip-install install-tomophantom
    conda env create --yes --name {{env-name}} --file environment.yml

# Delete Conda env
delete-env:
    -conda env remove --yes --name {{env-name}}

install-tomophantom:
    conda run --no-capture-output --name {{env-name}} -- bash -c 'git clone https://github.com/dkazanc/TomoPhantom.git \
        && mkdir TomoPhantom/build \
        && cd TomoPhantom/build \
        && cmake ../ -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
        && cmake --build . \
        && cmake --install . \
        && pip install .. \
        && cd ../.. \
        && rm -rf TomoPhantom'

# Installs required packages from PyPi
pip-install:
    conda run --no-capture-output --name {{env-name}} -- pip install \
        git+https://github.com/lebedov/scikit-cuda@0.5.1 \
        nabu[full]==2025.2.6 \
        git+https://github.com/RadWay-Tech-Services/tomocupy@62f439670f19065b67c02084c42d8cc80d98d7ab \
        tomobar==2026.3.1.0 \
        httomolib==4.2 \
        httomolibgpu==5.8.1 \
        httomo-backends==1.2.0 \
        httomo==3.2.1

# Creates synthetic Nexus file using tomophantom
generate-input detector-width="1024" detector-height="1024" projection-count="512" filename=default-nx:
    conda run --no-capture-output --name {{env-name}} -- python scripts/nxs_generator.py --output-path {{filename}} --sinogram-shape {{detector-height}} {{projection-count}} {{detector-width}}

generate-input-huge: (generate-input "2048" "4096" "2000" "synthetic-huge.nx")

generate-all: generate-input generate-input-huge

run-all input-file=default-nx: \
    (run-httomo "pipelines/httomo/fbp-preproc.yaml" input-file) \
    (run-httomo "pipelines/httomo/fbp.yaml" input-file) \
    (run-httomo "pipelines/httomo/lprec.yaml" input-file) \
    (run-nabu "pipelines/nabu/fbp-preproc.conf" input-file) \
    (run-nabu "pipelines/nabu/fbp.conf" input-file) \
    (run-tomocupy "pipelines/tomocupy/fbp-preproc.conf" input-file) \
    (run-tomocupy "pipelines/tomocupy/fbp.conf" input-file) \
    (run-tomocupy "pipelines/tomocupy/lprec.conf" input-file "recon")

# Run httomo tomography pipeline
run-httomo pipeline input-file=default-nx tasks="1":
    conda run --no-capture-output --name {{env-name}} -- mpirun -n {{tasks}} bash -c "time python -m httomo run {{input-file}} {{pipeline}} httomo-out"

# Run Nabu tomography pipeline
run-nabu pipeline input-file=default-nx gpus="1":
    # Need to edit and copy the config file to specify the input Nexus
    sed -e 's/synthetic.nx/{{input-file}}/g' -e 's/^gpus = [0-9]\+/gpus = {{gpus}}/' -e 's/^workers = [0-9]\+/workers = {{gpus}}/' {{pipeline}} > {{pipeline}}.tmp
    mkdir -p nabu-out
    conda run --no-capture-output --name {{env-name}} -- time bash -c 'PATH=$CONDA_PREFIX/nvvm/bin:$PATH nabu {{pipeline}}.tmp'
    rm {{pipeline}}.tmp

# Run tomocupy tomography pipeline
run-tomocupy pipeline input-file=default-nx subcommand="recon_steps":
    conda run --no-capture-output --name {{env-name}} -- time tomocupy {{subcommand}} --config {{pipeline}} --file-name {{input-file}} --out-path-name tomocupy-out --save-format h5nolinks

# Removes all non-version controlled files in the directory
cleanup:
    git clean -fdx

sbatch-all:
    sbatch batch/run-httomo-fbp-preproc.sbatch
    sbatch batch/run-httomo-fbp.sbatch
    sbatch batch/run-httomo-lprec.sbatch
    sbatch batch/run-nabu-fbp.sbatch
    sbatch batch/run-nabu-fbp-preproc.sbatch

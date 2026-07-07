default-env-name := "tomobenchmarks"
default-detector-width := "1024"
default-projection-count := "512"
default-detector-height := "1024"
default-nodes := "1"

# Recreate environment.yml
export-env env-name=default-env-name: (delete-env env-name)
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
recreate-env env-name=default-env-name: (delete-env env-name) && (pip-install env-name)
    conda env create --yes --name {{env-name}} --file environment.yml

# Delete Conda env
delete-env env-name=default-env-name:
    -conda env remove --yes --name {{env-name}}

# Installs required packages from PyPi
pip-install env-name=default-env-name:
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
generate-input env-name=default-env-name detector-width=default-detector-width detector-height=default-detector-height projection-count=default-projection-count:
    conda run --no-capture-output --name {{env-name}} -- python scripts/nxs_generator.py --output-path synthetic.nx --sinogram-shape {{detector-height}} {{projection-count}} {{detector-width}}

# Run httomo tomography pipeline
run-httomo env-name=default-env-name nodes=default-nodes:
    conda run --no-capture-output --name {{env-name}} -- mpirun -n {{nodes}} bash -c "time python -m httomo run synthetic.nx synthetic.yaml httomo-out"

# Run Nabu tomography pipeline
run-nabu env-name=default-env-name:
    mkdir -p nabu-out
    conda run --no-capture-output --name {{env-name}} -- bash -c "PATH=$CONDA_PREFIX/nvvm/bin:$PATH time nabu nabu-synthetic.conf"

# Run tomocupy tomography pipeline
run-tomocupy env-name=default-env-name:
    conda run --no-capture-output --name {{env-name}} -- time tomocupy recon --config tomocupy-synthetic.conf --out-path-name tomocupy-out --save-format h5nolinks

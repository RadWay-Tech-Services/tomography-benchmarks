#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse
import h5py
import numpy as np
import pathlib
import psutil
import tomophantom

"""
This script uses TomoPhantom to generate an NXtomo-compliant NeXus file, with HDF5 as the underlying storage format. Users can specify the model number, phantom shape, and angular range.

The script generates the phantom incrementally in chunks, based on the available system memory, and writes each chunk directly to the output file. This approach enables the creation of extremely large phantom datasets, even on systems with limited CPU memory.

Because the resulting NeXus file conforms to the NXtomo data standard, it can be read by multiple data-processing and reconstruction frameworks. This work was carried out to support testing of high-resolution datasets within the HTTomo big-data processing framework developed at Diamond Light Source:
https://github.com/DiamondLightSource/httomo

Example to generate (128 x 256 x 362) data file from the model no. 13 using the command line: python nxs_generator.py -m 13 -s 128 256 362
"""


def main(args: argparse.Namespace):
    model = args.model_number
    path = pathlib.Path(tomophantom.__file__).parent
    path_library3D = str(path / "phantomlib" / "Phantom3DLibrary.dat")

    sinogram_dtype = np.uint16()
    Horiz_det = args.sinogram_shape[2]
    Vert_det = args.sinogram_shape[0]
    angles_num = args.sinogram_shape[1]
    square_phantom_slice_width = int(Horiz_det / np.sqrt(2))

    angles = np.linspace(*args.angle_range, angles_num, dtype="float32")  # in degrees

    available_memory_bytes = min(psutil.virtual_memory().available, 32 * 1024**3)
    slice_memory_bytes = Horiz_det * angles_num * sinogram_dtype.itemsize
    if slice_memory_bytes > available_memory_bytes:
        print(
            f"A signle slice ({slice_memory_bytes} bytes) is would be bigger than available memory ({available_memory_bytes} bytes)."
        )
        return

    chunk_size = available_memory_bytes // slice_memory_bytes // 8
    chunk_count = int(np.ceil(Vert_det / chunk_size))
    print(
        f"Creating phantom in {chunk_count} number of chunks of at max {chunk_size} slices per chunk."
    )

    with h5py.File(args.output_path, "w") as file:
        entry_group = file.create_group("entry0000")
        entry_group.attrs["NX_class"] = "NXentry"
        entry_group.attrs["default"] = "data"
        entry_group.attrs["definition"] = "NXtomo"
        entry_group.attrs["version"] = 1.3

        instrument_group = entry_group.create_group("instrument")
        instrument_group.attrs["NX_class"] = "NXinstrument"
        detector_group = instrument_group.create_group("detector")
        detector_group.attrs["NX_class"] = "NXdetector"
        image_key = np.zeros([angles_num], dtype=np.int8)
        image_key_dataset = detector_group.create_dataset("image_key", data=image_key)
        detector_group["image_key_control"] = image_key_dataset
        detector_group["distance"] = 0.01
        detector_group["distance"].attrs["units"] = "m"
        detector_group["x_pixel_size"] = 0.000006
        detector_group["x_pixel_size"].attrs["units"] = "m"
        detector_group["y_pixel_size"] = 0.000006
        detector_group["y_pixel_size"].attrs["units"] = "m"

        beam_group = instrument_group.create_group("beam")
        beam_group.attrs["NX_class"] = "NXbeam"
        beam_group["incident_energy"] = 19.0
        beam_group["incident_energy"].attrs["units"] = "keV"

        entry_group.create_dataset("definition", data="NXtomo")
        data_group = entry_group.create_group("data")
        data_group.attrs["NX_class"] = "NXdata"
        data_group.attrs["SILX_style/axis_scale_types"] = ["linear", "linear"]
        sinogram_dataset = data_group.create_dataset(
            "data", (angles_num, Vert_det, Horiz_det), sinogram_dtype
        )
        sinogram_dataset.attrs["interpretation"] = "image"
        detector_group["data"] = sinogram_dataset
        data_group.attrs["signal"] = "data"

        # Compatibility with TomoCuPy
        exchange_group = file.create_group("exchange")
        exchange_group["data"] = sinogram_dataset
        exchange_group["theta"] = angles
        exchange_group["data_white"] = (
            np.ones((1, Vert_det, Horiz_det), dtype=sinogram_dtype) * 32535
        )
        exchange_group["data_dark"] = np.ones(
            (1, Vert_det, Horiz_det), dtype=sinogram_dtype
        )

        data_group.create_dataset(
            "rotation_angle",
            data=angles,
        )
        # Create hard link to the same rotation dataset
        entry_group["sample/rotation_angle"] = data_group["rotation_angle"]
        entry_group["sample"].attrs["NX_class"] = "NXsample"

        for i in range(chunk_count):
            chunk_start = i * chunk_size
            chunk_end = min((i + 1) * chunk_size, Vert_det)

            projData3D_analyt = tomophantom.TomoP3D.ModelSinoSub(
                model,
                square_phantom_slice_width,
                Horiz_det,
                Vert_det,
                (chunk_start, chunk_end),
                angles,
                path_library3D,
            )

            f_min, f_max = projData3D_analyt.min(), projData3D_analyt.max()
            projData3D_analyt = (
                (projData3D_analyt - f_min) / (f_max - f_min) * 65535
            ).astype(np.uint16)

            swapped_projData3D_analyt = np.swapaxes(projData3D_analyt, 0, 1)
            sinogram_dataset[:angles_num, chunk_start:chunk_end, :Horiz_det] = (
                swapped_projData3D_analyt
            )
            print(f"Chunk {i} done!")

    print(
        f"#slices: {Vert_det}, #projections: {angles_num}, detector width: {Horiz_det}"
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="TomoPhantom phantom .nxs generator. Output can be used with httomo, e.g. 'httomo run phantom.nxs pipeline.yaml output'."
    )
    parser.add_argument(
        "-m",
        "--model-number",
        type=int,
        default=13,  # Shepp-Logan
        help="Model number in TomoPhantom's model library. See https://github.com/dkazanc/TomoPhantom/tree/master/tomophantom/phantomlib.",
    )
    parser.add_argument(
        "-s",
        "--sinogram-shape",
        nargs=3,
        metavar=("detector height", "projection count", "detector width"),
        type=int,
        default=(2368, 256, 4416),
    )
    parser.add_argument(
        "-a",
        "--angle-range",
        nargs=2,
        metavar=("start", "end"),
        type=float,
        default=(0.0, 179.9),
    )
    parser.add_argument(
        "-o", "--output-path", type=pathlib.Path, default="./phantom.nxs"
    )

    args = parser.parse_args()
    main(args)

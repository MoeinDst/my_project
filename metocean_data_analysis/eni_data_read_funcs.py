# encoding: utf-8 , utf-16
'''
eni_data_read_funcs.py 

Series of functions that deal with reading
the `.csv` files provided from Eni and fugro.
Functions are mainly parsers that handle the
headers of the `.csv` file and extract data,
then put them in Xarray format. It also uses
the header part as metadata and writes them
in the attributes.

Version 1.0, moeindst, May 2026
'''

### importing libraries and packages
from pathlib import Path
import re
from io import StringIO

import xarray as xr
import pandas as pd
import numpy as np

### -------------------------------------------------------------------------------- ###
# def read_text_file(file_path):
#     for enc in ["utf-16", "utf-16-le", "utf-8-sig", "utf-8", "cp1252", "latin1"]:
#         try:
#             with open(file_path, "r", encoding=enc) as f:
#                 return f.readlines(), enc

#         except (UnicodeDecodeError, UnicodeError):
#             continue

#     raise UnicodeError(f"Could not decode file: {file_path}")

def read_text_file(file_path):

    encodings = ["utf-8-sig","utf-8","cp1252","latin1","utf-16","utf-16-le"]

    for enc in encodings:

        try:
            with open(file_path, "r", encoding=enc) as f:
                lines = f.readlines()

            # quick sanity check
            sample = "".join(lines[:20]).lower()

            if (
                "yyyy" in sample
                or "contract" in sample
                or "instrument type" in sample
            ):
                return lines, enc

        except (UnicodeDecodeError, UnicodeError):
            continue

    raise UnicodeError(f"Could not decode file: {file_path}")

### -------------------------------------------------------------------------------- ###

def _normalize_attr_key(key):
    key = key.strip().lower()
    key = re.sub(r"[^a-z0-9]+", "_", key).strip("_")
    return key

### -------------------------------------------------------------------------------- ###

def _read_common_attrs_and_header(lines):
    attrs = {}
    header_idx = None

    for i, line in enumerate(lines):
        clean = line.strip()
        text = clean.lstrip("%").strip()
        text_normalized = re.sub(r"\s+", " ", text)
        header_candidate = text_normalized.lower()

        # metadata
        if clean.startswith("%"):
            if ":" in text:
                key, value = text.split(":", 1)
                attrs[_normalize_attr_key(key)] = value.strip()

            if header_candidate.startswith("time zone"):
                attrs["time_zone"] = re.sub(
                    r"^time zone\s*:?", "", text_normalized, flags=re.IGNORECASE
                ).strip()

        # header detection: check all lines
        tokens = re.split(r"\s+", text.strip())

        if len(tokens) >= 5:
            first_five = [t.lower() for t in tokens[:5]]

            if first_five == ["yyyy", "mm", "dd", "hh", "mm"]:
                header_idx = i
                break

    return attrs, header_idx

### -------------------------------------------------------------------------------- ###

def _make_time_index(df):
    return pd.to_datetime(
        dict(
            year=df["yyyy"],
            month=df["mm"],
            day=df["dd"],
            hour=df["HH"],
            minute=df["MM"],
        ),
        errors="coerce"
    )

### -------------------------------------------------------------------------------- ###

def parse_sg_txt_to_dataset(file_path):
    file_path = Path(file_path)

    lines, encoding_used = read_text_file(file_path)

    attrs = {}
    header_idx = None

    for i, line in enumerate(lines):
        clean = line.strip()

        if clean.startswith("%"):
            text = clean.lstrip("%").strip()
            text_normalized = re.sub(r"\s+", " ", text)

            if ":" in text:
                key, value = text.split(":", 1)
                key = key.strip().lower()
                key = re.sub(r"[^a-z0-9]+", "_", key).strip("_")
                attrs[key] = value.strip()

            if text_normalized.upper().startswith("TIME ZONE"):
                attrs["time_zone"] = text_normalized.replace("TIME ZONE", "").strip()

            header_candidate = text_normalized.lower()

            if (
                "yyyy" in header_candidate
                and "mm" in header_candidate
                and "dd" in header_candidate
                and "hh" in header_candidate
            ):
                header_idx = i
                break

    if header_idx is None:
        raise ValueError(
            f"Could not find SG column header in {file_path.name}. "
            f"Encoding used: {encoding_used}"
        )

    data_start_idx = header_idx + 4

    columns = ["yyyy", "mm", "dd", "HH", "MM", "V", "theta_c", "Tw", "S"]

    data_text = "".join(lines[data_start_idx:])

    df = pd.read_csv(
        StringIO(data_text),
        sep=r"\s+",
        names=columns,
        engine="python"
    )

    for col in columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    df["time"] = pd.to_datetime(
        dict(
            year=df["yyyy"],
            month=df["mm"],
            day=df["dd"],
            hour=df["HH"],
            minute=df["MM"],
        ),
        errors="coerce"
    )

    df = df.dropna(subset=["time"]).set_index("time")

    attrs["source_file"] = file_path.name
    attrs["source_encoding"] = encoding_used
    attrs["data_type"] = "current_meter"
    attrs["instrument_family"] = "SG"

    ds = xr.Dataset(
        data_vars={
            "current_speed": ("time", df["V"].astype(float)),
            "current_direction": ("time", df["theta_c"].astype(float)),
            "temperature": ("time", df["Tw"].astype(float)),
            "salinity": ("time", df["S"].astype(float)),
        },
        coords={"time": df.index},
        attrs=attrs,
    )
    
    ds["time"].attrs = {
    "standard_name": "time",
    "long_name": "time",
    "timezone": attrs.get("time_zone", "UTC")
    }

    ds["current_speed"].attrs = {
        "units": "m s-1",
        "long_name": "current speed",
        "original_name": "V",
    }

    ds["current_direction"].attrs = {
        "units": "degree_true",
        "long_name": "current direction",
        "original_name": "theta_c",
    }

    ds["temperature"].attrs = {
        "units": "degree_Celsius",
        "long_name": "water temperature",
        "original_name": "Tw",
    }

    ds["salinity"].attrs = {
        "units": "PSU",
        "long_name": "salinity",
        "original_name": "S",
    }

    return ds

### -------------------------------------------------------------------------------- ###

def parse_rbr_txt_to_dataset(file_path):
    file_path = Path(file_path)

    lines, encoding_used = read_text_file(file_path)
    attrs, header_idx = _read_common_attrs_and_header(lines)

    if header_idx is None:
        raise ValueError(
            f"Could not find RBR column header in {file_path.name}. "
            f"Encoding used: {encoding_used}"
        )

    data_start_idx = header_idx + 4

    columns = ["yyyy", "mm", "dd", "HH", "MM", "Tw", "Turb", "S"]
    data_text = "".join(lines[data_start_idx:])

    df = pd.read_csv(
        StringIO(data_text),
        sep=r"\s+",
        names=columns,
        engine="python",
        na_values=[-999, -999.0, -999.00],
    )

    for col in columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    df["time"] = _make_time_index(df)
    df = df.dropna(subset=["time"]).set_index("time")

    attrs["source_file"] = file_path.name
    attrs["source_encoding"] = encoding_used
    attrs["data_type"] = "seawater_parameter"
    attrs["instrument_family"] = "RBR"

    ds = xr.Dataset(
        data_vars={
            "temperature": ("time", df["Tw"].astype(float)),
            "turbidity": ("time", df["Turb"].astype(float)),
            "salinity": ("time", df["S"].astype(float)),
        },
        coords={"time": df.index},
        attrs=attrs,
    )

    ds["time"].attrs = {
        "standard_name": "time",
        "long_name": "time",
        "timezone": attrs.get("time_zone", "UTC"),
    }

    ds["temperature"].attrs = {
        "units": "degree_Celsius",
        "long_name": "water temperature",
        "original_name": "Tw",
    }

    ds["turbidity"].attrs = {
        "units": "NTU",
        "long_name": "turbidity",
        "original_name": "Turb",
    }

    ds["salinity"].attrs = {
        "units": "PSU",
        "long_name": "salinity",
        "original_name": "S",
    }

    return ds

### -------------------------------------------------------------------------------- ###

def parse_wlr_txt_to_dataset(file_path):
    file_path = Path(file_path)

    lines, encoding_used = read_text_file(file_path)
    attrs, header_idx = _read_common_attrs_and_header(lines)

    if header_idx is None:
        raise ValueError(
            f"Could not find WLR column header in {file_path.name}. "
            f"Encoding used: {encoding_used}"
        )

    data_start_idx = header_idx + 4

    columns = ["yyyy", "mm", "dd", "HH", "MM", "Observed", "Predicted", "Residual"]
    data_text = "".join(lines[data_start_idx:])

    df = pd.read_csv(
        StringIO(data_text),
        sep=r"\s+",
        names=columns,
        engine="python",
        na_values=[-999, -999.0, -999.00],
    )

    for col in columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    df["time"] = _make_time_index(df)
    df = df.dropna(subset=["time"]).set_index("time")

    attrs["source_file"] = file_path.name
    attrs["source_encoding"] = encoding_used
    attrs["data_type"] = "tide_gauge"
    attrs["instrument_family"] = "WLR"

    ds = xr.Dataset(
        data_vars={
            "observed_water_level": ("time", df["Observed"].astype(float)),
            "predicted_water_level": ("time", df["Predicted"].astype(float)),
            "residual_water_level": ("time", df["Residual"].astype(float)),
        },
        coords={"time": df.index},
        attrs=attrs,
    )

    ds["time"].attrs = {
        "standard_name": "time",
        "long_name": "time",
        "timezone": attrs.get("time_zone", "UTC"),
    }

    ds["observed_water_level"].attrs = {
        "units": "m",
        "long_name": "observed water level",
        "original_name": "Observed",
    }

    ds["predicted_water_level"].attrs = {
        "units": "m",
        "long_name": "predicted water level",
        "original_name": "Predicted",
    }

    ds["residual_water_level"].attrs = {
        "units": "m",
        "long_name": "residual water level",
        "original_name": "Residual",
    }

    return ds

### -------------------------------------------------------------------------------- ###

def parse_sbe37_txt_to_dataset(file_path):
    file_path = Path(file_path)

    lines, encoding_used = read_text_file(file_path)
    attrs, header_idx = _read_common_attrs_and_header(lines)

    if header_idx is None:
        raise ValueError(
            f"Could not find SBE37 column header in {file_path.name}. "
            f"Encoding used: {encoding_used}"
        )

    data_start_idx = header_idx + 4

    columns = ["yyyy", "mm", "dd", "HH", "MM", "Tw", "S"]
    data_text = "".join(lines[data_start_idx:])

    df = pd.read_csv(
        StringIO(data_text),
        sep=r"\s+",
        names=columns,
        engine="python",
        na_values=[-999, -999.0, -999.00],
    )

    for col in columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    df["time"] = _make_time_index(df)
    df = df.dropna(subset=["time"]).set_index("time")

    attrs["source_file"] = file_path.name
    attrs["source_encoding"] = encoding_used
    attrs["data_type"] = "seawater_parameter"
    attrs["instrument_family"] = "SBE37"

    ds = xr.Dataset(
        data_vars={
            "temperature": ("time", df["Tw"].astype(float)),
            "salinity": ("time", df["S"].astype(float)),
        },
        coords={"time": df.index},
        attrs=attrs,
    )

    ds["time"].attrs = {
        "standard_name": "time",
        "long_name": "time",
        "timezone": attrs.get("time_zone", "UTC"),
    }

    ds["temperature"].attrs = {
        "units": "degree_Celsius",
        "long_name": "water temperature",
        "original_name": "Tw",
    }

    ds["salinity"].attrs = {
        "units": "PSU",
        "long_name": "salinity",
        "original_name": "S",
    }

    return ds

### -------------------------------------------------------------------------------- ###

def parse_profile_current_txt_to_dataset(file_path):
    file_path = Path(file_path)

    lines, encoding_used = read_text_file(file_path)
    attrs, header_idx = _read_common_attrs_and_header(lines)

    if header_idx is None:
        raise ValueError(
            f"Could not find current-profile column header in {file_path.name}. "
            f"Encoding used: {encoding_used}"
        )

    # Find vertical coordinate line dynamically
    vertical_type = None
    vertical_values = None

    for line in lines:
        text = line.strip().lstrip("%").strip()
        text_norm = re.sub(r"\s+", " ", text).lower()

        if text_norm.startswith("height m"):
            vertical_type = "height_above_bed"
            vertical_values = [
                float(x) for x in re.findall(r"-?\d+(?:\.\d+)?", text)
            ]
            break

        if text_norm.startswith("depth m"):
            vertical_type = "depth_below_msl"
            vertical_values = [
                float(x) for x in re.findall(r"-?\d+(?:\.\d+)?", text)
            ]
            break

    if vertical_values is None:
        raise ValueError(
            f"Could not find HEIGHT m or DEPTH m line in {file_path.name}"
        )

    n_levels = len(vertical_values)

    # Find first actual numeric data row dynamically
    data_start_idx = None

    for i in range(header_idx + 1, len(lines)):
        clean = lines[i].strip()

        if not clean or clean.startswith("%"):
            continue

        if re.match(r"^\d{4}\s+", clean):
            data_start_idx = i
            break

    if data_start_idx is None:
        raise ValueError(
            f"Could not find current-profile data start in {file_path.name}"
        )

    # Date columns + V/theta pair for each level
    columns = ["yyyy", "mm", "dd", "HH", "MM"]

    for level_i in range(1, n_levels + 1):
        columns.extend([f"V_level{level_i}", f"theta_c_level{level_i}"])

    data_text = "".join(lines[data_start_idx:])

    df = pd.read_csv(
        StringIO(data_text),
        sep=r"\s+",
        names=columns,
        engine="python",
        na_values=[-999, -999.0, -999.00],
    )

    for col in columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    df["time"] = _make_time_index(df)
    df = df.dropna(subset=["time"]).set_index("time")

    # Build 2D arrays: time x level
    speed_cols = [f"V_level{i}" for i in range(1, n_levels + 1)]
    direction_cols = [f"theta_c_level{i}" for i in range(1, n_levels + 1)]

    current_speed = df[speed_cols].to_numpy(dtype=float)
    current_direction = df[direction_cols].to_numpy(dtype=float)

    attrs["source_file"] = file_path.name
    attrs["source_encoding"] = encoding_used
    attrs["data_type"] = "current_profile"

    instrument_type = attrs.get("instrument_type", "").upper()

    if "AQUADOPP" in instrument_type:
        attrs["instrument_family"] = "Aquadopp"
    elif "WHW" in instrument_type:
        attrs["instrument_family"] = "WHWADCP"
    elif "WH" in instrument_type:
        attrs["instrument_family"] = "WHADCP"
    else:
        attrs["instrument_family"] = "ADCP"

    ds = xr.Dataset(
        data_vars={
            "current_speed": (("time", "level"), current_speed),
            "current_direction": (("time", "level"), current_direction),
            vertical_type: ("level", vertical_values),
        },
        coords={
            "time": df.index,
            "level": list(range(1, n_levels + 1)),
        },
        attrs=attrs,
    )

    ds["time"].attrs = {
        "standard_name": "time",
        "long_name": "time",
        "timezone": attrs.get("time_zone", "UTC"),
    }

    ds["level"].attrs = {
        "long_name": "instrument bin / depth level",
    }

    ds[vertical_type].attrs = {
        "units": "m",
        "long_name": vertical_type.replace("_", " "),
    }

    ds["current_speed"].attrs = {
        "units": "m s-1",
        "long_name": "current speed",
        "original_name": "V",
    }

    ds["current_direction"].attrs = {
        "units": "degree_true",
        "long_name": "current direction",
        "original_name": "theta_c",
        "direction_convention": "towards",
    }

    return ds

### -------------------------------------------------------------------------------- ###

def parse_wave_txt_to_dataset(file_path):
    file_path = Path(file_path)

    lines, encoding_used = read_text_file(file_path)
    attrs, header_idx = _read_common_attrs_and_header(lines)

    if header_idx is None:
        raise ValueError(
            f"Could not find wave column header in {file_path.name}. "
            f"Encoding used: {encoding_used}"
        )

    data_start_idx = None

    for i in range(header_idx + 1, len(lines)):
        clean = lines[i].strip()

        if not clean or clean.startswith("%"):
            continue

        if re.match(r"^\d{4}\s+", clean):
            data_start_idx = i
            break

    if data_start_idx is None:
        raise ValueError(
            f"Could not find wave data start in {file_path.name}"
        )

    header_text = lines[header_idx].strip().lstrip("%").strip()
    columns = re.split(r"\s+", header_text)

    data_text = "".join(lines[data_start_idx:])

    df = pd.read_csv(
        StringIO(data_text),
        sep=r"\s+",
        names=columns,
        engine="python",
        na_values=[-999, -999.0, -999.00],
    )

    for col in columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    df["time"] = _make_time_index(df)
    df = df.dropna(subset=["time"]).set_index("time")

    attrs["source_file"] = file_path.name
    attrs["source_encoding"] = encoding_used
    attrs["data_type"] = "wave_parameter"

    instrument_type = attrs.get("instrument_type", "").upper()

    if "WHW" in instrument_type:
        attrs["instrument_family"] = "WHWADCP_Waves"
    else:
        attrs["instrument_family"] = "Waves"

    data_vars = {}

    variable_map = {
        "Cmax": ("maximum_crest_elevation", "m", "maximum crest elevation"),
        "Hs": ("significant_wave_height", "m", "significant wave height"),
        "Hmax": ("maximum_wave_height", "m", "maximum wave height"),
        "θH": ("wave_direction", "degree_true", "wave direction"),
        "SPREADING": ("directional_spreading", "degree_true", "directional spreading"),
        "Thmax": ("maximum_wave_period", "s", "maximum wave period"),
        "Tm": ("mean_wave_period", "s", "mean wave period"),
        "Tp": ("peak_wave_period", "s", "peak wave period"),
    }

    for original_name, (new_name, units, long_name) in variable_map.items():
        if original_name in df.columns:
            data_vars[new_name] = ("time", df[original_name].astype(float))

    ds = xr.Dataset(
        data_vars=data_vars,
        coords={"time": df.index},
        attrs=attrs,
    )

    ds["time"].attrs = {
        "standard_name": "time",
        "long_name": "time",
        "timezone": attrs.get("time_zone", "UTC"),
    }

    for original_name, (new_name, units, long_name) in variable_map.items():
        if new_name in ds:
            ds[new_name].attrs = {
                "units": units,
                "long_name": long_name,
                "original_name": original_name,
            }

    return ds

### -------------------------------------------------------------------------------- ###

def _find_data_start_idx(lines, header_idx):
    for i in range(header_idx + 1, len(lines)):
        clean = lines[i].strip()

        if not clean or clean.startswith("%"):
            continue

        if re.match(r"^\d{4}\s+", clean):
            return i

    raise ValueError("Could not find first numeric data row")

### -------------------------------------------------------------------------------- ###

def parse_met_txt_to_dataset(file_path):
    file_path = Path(file_path)

    lines, encoding_used = read_text_file(file_path)
    attrs, header_idx = _read_common_attrs_and_header(lines)

    if header_idx is None:
        raise ValueError(
            f"Could not find MET column header in {file_path.name}. "
            f"Encoding used: {encoding_used}"
        )

    data_start_idx = _find_data_start_idx(lines, header_idx)

    header_text = lines[header_idx].strip().lstrip("%").strip()
    columns = re.split(r"\s+", header_text)

    data_text = "".join(lines[data_start_idx:])

    df = pd.read_csv(
        StringIO(data_text),
        sep=r"\s+",
        names=columns,
        engine="python",
        na_values=[-999, -999.0, -999.00],
    )

    for col in columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    time = _make_time_index(df)

    attrs["source_file"] = file_path.name
    attrs["source_encoding"] = encoding_used
    attrs["data_type"] = "meteorological"
    attrs["instrument_family"] = "Met Station"

    variable_map = {
        "Ws": ("wind_speed", "m s-1", "wind speed"),
        "θW": ("wind_direction", "degree_true", "wind direction"),
        "Wg": ("wind_gust", "m s-1", "wind gust"),
        "RH": ("relative_humidity", "%", "relative humidity"),
        "Pa": ("air_pressure", "mbar", "air pressure"),
        "Ta": ("air_temperature", "degree_Celsius", "air temperature"),
    }

    data_vars = {}

    for original_name, (new_name, units, long_name) in variable_map.items():
        if original_name in df.columns:
            data_vars[new_name] = ("time", df[original_name].astype(float))

    ds = xr.Dataset(
        data_vars=data_vars,
        coords={"time": time},
        attrs=attrs,
    )

    ds["time"].attrs = {
        "standard_name": "time",
        "long_name": "time",
        "timezone": attrs.get("time_zone", "UTC"),
    }

    for original_name, (new_name, units, long_name) in variable_map.items():
        if new_name in ds:
            ds[new_name].attrs = {
                "units": units,
                "long_name": long_name,
                "original_name": original_name,
            }

    if "wind_direction" in ds:
        ds["wind_direction"].attrs["direction_convention"] = "towards"

    return ds

### -------------------------------------------------------------------------------- ###

def chunk_dataset_adaptive(ds, target_time_chunk=1000):
    n_time = ds.sizes["time"]

    n_chunks = max(1, round(n_time / target_time_chunk))
    time_chunk = int(np.ceil(n_time / n_chunks))

    chunks = {"time": time_chunk}

    if "level" in ds.dims:
        chunks["level"] = -1

    return ds.chunk(chunks)

### -------------------------------------------------------------------------------- ###

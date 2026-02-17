from pathlib import Path


class TSVInputError(Exception):
    """Base exception for TSV input errors."""


class TSVHeaderError(TSVInputError):
    """Raised when required headers are missing."""


class TSVNoDataError(TSVInputError):
    """Raised when no data rows are found after header."""


class TSVRequiredFieldError(TSVInputError):
    """Raised when a required field is missing or empty."""


class TSVFileMissingError(TSVInputError):
    """Raised when a required file does not exist."""


REQUIRED_INPUT_COLUMNS = [
    "sample",
    "family",
    "filtering",
    "track",
    "vcf",
]  # 'bam' is optional


def tsv_to_family_dict(tsv_path):
    family_dict = {}
    with open(tsv_path, "r") as f:
        lines = [line.rstrip("\n") for line in f if line.strip()]
        if not lines:
            raise TSVInputError("Input file is empty or contains only blank lines.")

        headers = [h.strip() for h in lines[0].split("\t")]
        missing_headers = [h for h in REQUIRED_INPUT_COLUMNS if h not in headers]
        if missing_headers:
            raise TSVHeaderError(
                f"Missing required headers: {', '.join(missing_headers)}"
            )

        if len(lines) == 1:
            raise TSVNoDataError("No data rows found after header.")

        family_idx = headers.index("family")
        sample_idx = headers.index("sample")
        vcf_idx = headers.index("vcf")

        for line_number, line in enumerate(lines[1:]):
            cols = [c.strip() if c.strip() != "" else None for c in line.split("\t")]
            if len(cols) < len(headers):
                cols += [None] * (len(headers) - len(cols))

            # Enforce required fields are not None or empty
            for field, idx in [
                ("family", family_idx),
                ("sample", sample_idx),
                ("vcf", vcf_idx),
            ]:
                value = cols[idx]
                if value is None or str(value).strip() == "":
                    raise TSVRequiredFieldError(
                        f"'{field}' is required and missing or empty in line {line_number + 2}."
                    )

            row_dict = {h: cols[i] for i, h in enumerate(headers) if h != "family"}
            family = cols[family_idx]
            family_dict.setdefault(family, []).append(row_dict)
    return family_dict


def validate_files_exist(family_dict, file_keys=("vcf", "ped", "bam")):
    """
    Checks that all files referenced by file_keys in the family_dict exist.
    Raises TSVFileMissingError if any file is missing.
    'bam' is optional in the TSV, but if present, its path is validated.
    """
    for family, samples in family_dict.items():
        for sample in samples:
            for key in file_keys:
                file_path = sample.get(key)
                if file_path and not Path(file_path).exists():
                    raise TSVFileMissingError(
                        f"File for '{key}' does not exist: {file_path} (family: {family}, sample: {sample.get('sample')})"
                    )


def get_samples_with_bam(family_dict):
    """
    Return a list of sample dicts that have a non-empty 'bam' field.
    """
    samples = []
    for fam_samples in family_dict.values():
        for sample in fam_samples:
            bam = sample.get("bam")
            if bam:
                samples.append(sample)
    return samples


def get_family_of_sample(family_dict, sample_name):
    """
    Return the family name for the given sample_name, or None if not found.
    """
    for family, samples in family_dict.items():
        for sample in samples:
            if sample.get("sample") == sample_name:
                return family
    return None

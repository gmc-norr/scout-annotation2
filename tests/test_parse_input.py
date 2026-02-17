import pytest
from pathlib import Path
from workflow.parse_input import (
    tsv_to_family_dict,
    validate_files_exist,
    TSVInputError,
    TSVHeaderError,
    TSVNoDataError,
    TSVRequiredFieldError,
    TSVFileMissingError,
)

@pytest.fixture
def data_dir():
    return Path(__file__).parent / "data"

@pytest.fixture
def valid_multi_expected():
    return {
        "fam1": [
            {
                "sample": "sample1",
                "filtering": "filter1",
                "track": "track1",
                "vcf": "file1.vcf"
            },
            {
                "sample": "sample2",
                "filtering": "filter2",
                "track": "track2",
                "vcf": "file2.vcf"
            }
        ],
        "fam2": [
            {
                "sample": "sample3",
                "filtering": "filter3",
                "track": "track3",
                "vcf": "file3.vcf"
            }
        ]
    }

def test_empty_input_file(data_dir):
    tsv = data_dir / "empty.tsv"
    with pytest.raises(TSVInputError):
        tsv_to_family_dict(str(tsv))

def test_missing_required_header(data_dir):
    tsv = data_dir / "missing_required_header.tsv"
    with pytest.raises(TSVHeaderError):
        tsv_to_family_dict(str(tsv))

def test_no_data_rows(data_dir):
    tsv = data_dir / "no_rows.tsv"
    with pytest.raises(TSVNoDataError):
        tsv_to_family_dict(str(tsv))

def test_missing_family_field(data_dir):
    tsv = data_dir / "missing_family.tsv"
    with pytest.raises(TSVRequiredFieldError, match="'family' is required and missing or empty in line 2."):
        tsv_to_family_dict(str(tsv))

def test_missing_sample_field(data_dir):
    tsv = data_dir / "missing_sample.tsv"
    with pytest.raises(TSVRequiredFieldError, match="'sample' is required and missing or empty in line 2."):
        tsv_to_family_dict(str(tsv))

def test_missing_vcf_field(data_dir):
    tsv = data_dir / "missing_vcf.tsv"
    with pytest.raises(TSVRequiredFieldError, match="'vcf' is required and missing or empty in line 3."):
        tsv_to_family_dict(str(tsv))

def test_valid_multi_sample_file(data_dir, valid_multi_expected):
    tsv = data_dir / "valid_multi.tsv"
    result = tsv_to_family_dict(str(tsv))
    # Only compare relevant keys for each sample
    for fam, samples in valid_multi_expected.items():
        for i, sample in enumerate(samples):
            for key, value in sample.items():
                assert result[fam][i][key] == value

def test_validate_files_exist_success(data_dir):
    tsv = data_dir / "all_files_exist.tsv"
    family_dict = tsv_to_family_dict(str(tsv))
    # Should not raise
    validate_files_exist(family_dict, file_keys=('vcf', 'ped'))

def test_validate_files_exist_missing(data_dir):
    tsv = data_dir / "missing_file.tsv"
    family_dict = tsv_to_family_dict(str(tsv))
    with pytest.raises(TSVFileMissingError, match="does_not_exist.vcf"):
        validate_files_exist(family_dict, file_keys=('vcf', 'ped'))
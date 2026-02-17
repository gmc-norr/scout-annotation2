from parse_input import tsv_to_family_dict, validate_files_exist, get_samples_with_bam


def get_input():
    """
    load and validate the family dict from the input file specified in config.
    Returns the family dict if validation succeeds.
    """

    input_file = config["input_file"]
    family_dict = tsv_to_family_dict(input_file)
    validate_files_exist(family_dict)
    return family_dict


def get_final_annotated_vcfs(input_data: dict, annotation_dir: str):
    """
    Return a list of final annotated VCF paths for each family.
    """
    return [
        f"{annotation_dir}/{family}/{family}.scout_anno.vcf.gz"
        for family in input_data.keys()
    ]


def get_final_d4s(input_data: dict, coverage_dir: str):
    """
    Return a list of coverage d4 file paths for all samples with bam files.
    Each path is f"{coverage_dir}/{family}/{sample}_coverage.d4"
    """
    d4s = []
    for sample in get_samples_with_bam(input_data):
        family = None
        # Find the family for this sample
        for fam, fam_samples in input_data.items():
            if sample in [sample_dict["sample"] for sample_dict in fam_samples]:
                family = fam
                break
        if family:
            d4s.append(f"{coverage_dir}/{family}/{sample['sample']}_coverage.d4")
    return d4s


# Helper to get all samples for a family
def get_family_samples(family_dict, family):
    return [s["sample"] for s in family_dict[family]]


# Helper to get the family VCF path (customize as needed)
def get_family_vcf(family, annotation_dir):
    # Example: annotation_dir/family/family.vcf
    return f"{annotation_dir}/{family}/{family}.vcf"


# Helper to get the sample translation file path
def get_sample_translation_path(family, sample):
    return f"decompose/{family}/{sample}.samples.txt"

def get_family_track(input_data: dict, family: str):
    return f"{annotation_dir}/{family}/{family}.track.txt"

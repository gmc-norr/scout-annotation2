rule vep:
    input:
        vcf=f"{decompose_dir}/{{family}}/{{family}}.decomposed.normalized.uniq.fix-af.vcf",
        tabix=f"{decompose_dir}/{{family}}/{{family}}.decomposed.normalized.uniq.fix-af.vcf.tbi",
        fasta=config["reference"]["fasta"],
        cache=config["vep"]["cache"],
        plugin=config["vep"]["plugin"],
        plugin_data=config["vep"]["plugin-data"],
        swegen=config["vep"]["swegen"],
        clinvar=config["vep"]["clinvar"],
    output:
        vcf=temp(f"{annotation_dir}/{{family}}/{{family}}.decomposed.vep.vcf"),
    log:
        f"{annotation_dir}/{{family}}/{{family}}.decomposed.vep.log",
    params:
        mode=config.get("vep", {}).get("mode", ""),
        cache_type=config.get("vep", {}).get("cache_type", "merged"),
    container:
        "docker://hydragenetics/vep:105"
    shell:
        """
        vep {params.mode} \\
            -i {input.vcf} \\
            -o {output.vcf} \\
            --vcf \\
            --assembly GRCh37 \\
            --dir_plugins {input.plugin} \\
            --plugin CADD,{input.plugin_data}/CADD_1.6/whole_genome_SNVs.tsv.gz,{input.plugin_data}/CADD_1.6/InDels.tsv.gz \\
            --plugin LoFtool,{input.plugin}/LoFtool_scores.txt \\
            --plugin MaxEntScan,{input.plugin_data}/MaxEntScan,SWA,NCS \\
            --plugin REVEL,{input.plugin_data}/revel_1.3/new_tabbed_revel.tsv.gz \\
            --plugin dbNSFP,{input.plugin_data}/dbNSFP_4.1a/dbNSFP4.1a_grch37.gz,GERP++_RS,phastCons100way_vertebrate,phyloP100way_vertebrate \\
            --custom {input.clinvar},CLINVAR,vcf,exact,0,CLNSIG,CLNREVSTAT \\
            --custom {input.swegen},SweGen,vcf,exact,0,AF \\
            --dir_cache {input.cache} \\
            --fork {threads} \\
            --distance 5000 \\
            --buffer_size 2000 \\
            --fasta {input.fasta} \\
            --check_existing \\
            --pick \\
            --sift b \\
            --polyphen b \\
            --ccds \\
            --uniprot \\
            --hgvs \\
            --symbol \\
            --numbers \\
            --domains \\
            --regulatory \\
            --canonical \\
            --protein \\
            --biotype \\
            --uniprot \\
            --tsl \\
            --appris \\
            --gene_phenotype \\
            --af \\
            --af_1kg \\
            --af_gnomad \\
            --max_af \\
            --pubmed \\
            --variant_class \\
            --exclude_predicted \\
            --humdiv \\
            --no_stats \\
            --{params.cache_type} \\
            &> {log}
        """

rule vcfanno_config:
    output:
        toml=get_vcfanno_config,
    log:
        f"{rank_model_dir}/grch{{build}}_{{track}}_vcfanno_config_{{version}}.log",
    params:
        uri=lambda wc: config["vcfanno"]["config_uri"].format(
            track=wc.track, version=wc.version
        ),
        extra=config.get("vcfanno_config", {}).get("extra", ""),
    container:
        "docker://bschiffthaler/curl:7.72.0"
    localrule: True
    shell:
        """
        echo "fetching {params.uri}" > {log}
        curl {params.extra} -fsSL {params.uri} > {output.toml} 2>> {log}

rule vcfanno:
    input:
        vcf=f"{annotation_dir}/{{family}}/{{family}}.decomposed.vep.vcf",
        toml=get_vcfanno_config,
    output:
        vcf=temp(f"{annotation_dir}/{{family}}/{{family}}.decomposed.vep.vcfanno.vcf"),
    log:
        f"{annotation_dir}/{{family}}/{{family}}.vcfanno.log",
    params:
        base_path=config.get("vcfanno", {}).get("base_path", ""),
    container:
        "docker://clinicalgenomics/vcfanno:0.3.2"
    shell:
        """
        vcfanno \\
            -base-path {params.base_path} \\
            -p {threads} \\
            {input.toml} \\
            {input.vcf} \\
            > {output.vcf} \\
            2> {log}
        """




# Is this used?????
rule most_severe_consequence:
    input:
        vcf=f"{annotation_dir}/{{family}}/{{family}}.decomposed.vep.vcfanno.vcf",
    output:
        vcf=temp(f"{annotation_dir}/{{family}}/{{family}}.annotated.vcf"),
    log:
        f"{annotation_dir}/{{family}}/{{family}}.most_severe_consequence.log",
    conda:
        "../env/most_severe_consequence.yaml"
    script:
        "../scripts/most_severe_consequence.py"
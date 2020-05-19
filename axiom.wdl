version 1.0

task Dqc {
    input {
        Array[File] cel_files
        File? cel_files_file
        File library_files_zip
        String? xml_file
        Float dqc_threshold = 0.82
        String docker_image = "apt/2.11.0:latest"
    }

    meta {
        description: "Process one or more CEL files with apt-geno-qc."
    }

    parameter_meta {
        cel_files: {
            description: "Set of 1 of more CEL files to be analysed.",
            extension: ".CEL"
        }
        cel_files_file: {
            description: "TXT file with the header 'cel_files' followed by a CEL file per line.",
            extension: ".txt"
        }
        library_files_zip: {
            description: "Zip archive of Axiom Library Files in root.",
            extension: ".zip"
        }
        xml_file: {
            description: "Name of XML file to be used by apt-geno-qc"
        }
        dqc_threshold: "Theshold below which a CEL file fails DQC."
        docker_image: "Docker image to use"
    }

    command <<<
    set -uexo pipefail
    if [ -z ~{cel_files_file} ]
    then
        echo "cel_files" > cel_files.txt
        echo '~{sep="\n" cel_files}' >> cel_files.txt
        cel_files_file=cel_files.txt
    else
        cel_files_file=~{cel_files_file}
        for x in ~{sep=" " cel_files} ; do
            ln -s $x .
        done
    fi
    unzip ~{library_files_zip} -d library_files
    if [ -z ~{xml_file}]
    then
        xml_file=$(find library_files -name *AxiomQC1*)
    else
        xml_file=~{xml_file}
    fi
    apt-geno-qc -analysis-files-path library_files -cel-files $cel_files_file -xml-file $xml_file -out-file dqc_report.txt
    grep -v ^# dqc_report.txt | awk '{print $1 "\t" $18}' > dqc_simple.txt
    cat dqc_simple.txt | awk '$2 >= ~{dqc_threshold} {print $1}' > passing_cel_files.txt
    cat dqc_simple.txt | awk '$2 < ~{dqc_threshold} {print $1}' > failing_cel_files.txt
    >>>

    runtime {
    docker: docker_image
    cpu: "4"
    memory: "2 GB"
    disks: "local-disk 20 SSD"
    }

    output{
        File report_file = "dqc_report.txt"
        File passing_cel_files_file = "passing_cel_files.txt"
        File failing_cel_files_file = "failing_cel_files.txt"
    }
}

task Step1Genotype {
    input{
        Array[File] cel_files
        File? cel_files_file
        File library_files_zip
        String? xml_file
        Float? cr_fail_threshold
        Float cr_pass_threshold = 97.0
        String docker_image = "apt/2.11.0:latest"
    }

    Float actual_cr_fail_threshold = select_first([cr_fail_threshold, cr_pass_threshold])


    meta {
        description: "Step1 Genotyping of DQC passing cel_file with apt-genotype-axiom."
    }
    parameter_meta {
        cel_files: {
            description: "Set of 1 of more CEL files to be analysed.",
            extension: ".CEL"
        }
        cel_files_file: {
            description: "TXT file with the header 'cel_files' followed by a CEL file per line.",
            extension: ".txt"
        }
        library_files_zip: {
            description: "Zip archive of Axiom Library Files in root.",
            extension: ".zip"
        }
        xml_file: {
            description: "Name of XML file to be used by apt-genotype-axiom"
        }
        cr_fail_threshold: "Theshold below which a CEL file fails Call Rate."
        cr_pass_threshold: "Theshold above which a CEL file passes Call Rate."
        docker_image: "Docker image to use"
    }

    command <<<
        set -uexo pipefail
        if [ -z ~{cel_files_file} ]
        then
            echo "cel_files" > cel_files.txt
            echo '~{sep="\n" cel_files}' >> cel_files.txt
            cel_files_file=cel_files.txt
        else
            cel_files_file=~{cel_files_file}
            for x in ~{sep=" " cel_files} ; do
                ln -s $x .
            done
        fi
        if [ -z ~{cr_fail_threshold} ]
        then
            cr_fail_threshold=~{cr_pass_threshold}
        fi
        unzip ~{library_files_zip} -d library_files
        if [ -z ~{xml_file} ]
        then
            xml_file=$(find library_files -name *Step1*)
        else
            xml_file=~{xml_file}
        fi

        apt-genotype-axiom --analysis-files-path library_files --arg-file $xml_file --cel-files $cel_files_file --dual-channel-normalization true --log-file apt-genotype-axiom.log
        grep -v ^# AxiomGT1.report.txt | awk '{print $1 "\t" $4}' > step1_simple.txt
        cat step1_simple.txt | awk '$2 >= ~{cr_pass_threshold} {print $1}' > passing_cel_files.txt
        cat step1_simple.txt | awk '$2 < ~{actual_cr_fail_threshold} {print $1}' > failing_cel_files.txt
        cat step1_simple.txt | awk '($2 < ~{cr_pass_threshold} && $2 >= ~{actual_cr_fail_threshold}){print $1}' > rescuable_cel_files.txt
    >>>

    runtime {
    docker: docker_image
    cpu: "4"
    memory: "2 GB"
    disks: "local-disk 20 SSD"
    }

    output{
        File report_file = "AxiomGT1.report.txt"
        File passing_cel_files_file = "passing_cel_files.txt"
        File failing_cel_files_file = "failing_cel_files.txt"
        File rescuable_cel_files_file = "rescuable_cel_files.txt"
    }
}

task Step2Genotype {
    input{
        Array[File] cel_files
        File? cel_files_file
        File library_files_zip
        File? priors_file
        String? xml_file
        Float? cr_pass_threshold
        Boolean rescue_genotyping = false
        String docker_image = "apt/2.11.0:latest"
        String? output_prefix
    }
    Float actual_cr_pass_threshold = select_first([cr_pass_threshold, 0.0])
    meta {
        description: "Step2 Genotyping of Step1 passing cel_files with apt-genotype-axiom."
    }

    parameter_meta {
        cel_files_file: {
            description: "TXT file with the header 'cel_files' followed by a CEL file per line.",
            extension: ".txt"
        }
        library_files_zip: {
            description: "Zip archive of Axiom Library Files in root.",
            extension: ".zip"
        }
        priors_file: {
            description: "Priors model file to be sued by apt-genotype-axiom",
            extension: "txt"
        }
        xml_file: {
            description: "Name of XML file to be used by apt-geno-qc"
        }
        cr_pass_threshold: "Theshold above which a CEL file passes Call Rate."
        rescue_genotyping: "True/False whether to apply no prior update"
        docker_image: "Docker image to use"
        output_prefix: "Prefix appended to all file outputs"

    }

    command <<<
        set -uexo pipefail
        if [ -z ~{cel_files_file} ]
        then
            echo "cel_files" > cel_files.txt
            echo '~{sep="\n" cel_files}' >> cel_files.txt
            cel_files_file=cel_files.txt
        else
            cel_files_file=~{cel_files_file}
            for x in ~{sep=" " cel_files} ; do
                ln -s $x .
            done
        fi
        unzip ~{library_files_zip} -d library_files
        if [ -z ~{xml_file} ]
        then
            xml_file=$(find library_files -name *Step2*)
        else
            xml_file=~{xml_file}
        fi
        additional_args=""
        if [ ~{rescue_genotyping} ]
        then
            additional_args="--brlmmp-CM 2"
        else
            additional_args="--brlmmp-CM 1"
        fi
        if [ ! -z ~{priors_file} ]
        then
            additional_args="${additional_args} --snp-priors-input-file ~{priors_file} "
        fi
        apt-genotype-axiom --analysis-files-path library_files --arg-file $xml_file --cel-files $cel_files_file --log-file apt-genotype-axiom.log --dual-channel-normalization true --allele-summaries true --snp-posteriors-output true $additional_args
        grep -v ^# AxiomGT1.report.txt | awk '{print $1 $4}' > report_simple.txt
        cat report_simple.txt | awk '$2 >= ~{actual_cr_pass_threshold} {print $1}' > passing_cel_files.txt

    >>>

    runtime {
    docker: docker_image
    cpu: "4"
    memory: "2 GB"
    disks: "local-disk 20 SSD"
    }

    output{
        File report_file = "AxiomGT1.report.txt"
        File calls_file = "AxiomGT1.calls.txt"
        File posteriors_file = "AxiomGT1.snp-posteriors.txt"
        File summary_file = "AxiomGT1.summary.txt"
        File confidences_file = "AxiomGT1.confidences.txt"
        File passing_cel_files_file = "passing_cel_files.txt"
    }


}

task GatherGenotypes {
    input {
        Array[File] report_files
        Array[File] calls_files
        Array[File] posteriors_files
        Array[File] confidences_files
        String pid_file_name
    }

    meta {
        description: "Gather step for parrellelised genotyping"
    }

    command <<<
        i=0
        for report_file in ~{report_files} ; do
            if $i=0
            then
                sed '/^#/ d'$report_file > AxiomGT1.report.txt
            else
                sed '/^#/ d'$report_file | sed -n '1!p' >> AxiomGT1.report.txt
            fi
            i=$i+1
        done
        #work out this grep to replace subsetted pid
        grep AxiomGT1.report.txt #%affymetrix-algorithm-param-apt-opt-probeset-ids=Axiom_PMRA.r3.step2.ps
        i=0
        for calls_file in ~{calls_files} ; do
            if $i=0
            then
                cat $calls_file > AxiomGT1.calls.txt
            else
                sed '/^#/ d' $calls_file | sed -n '1!p' >> AxiomGT1.calls.txt
            fi
            i=$i+1
        done
        i=0
        for posteriors_file in ~{posteriors_files} ; do
            if $i=0
            then
                cat $posteriors_file >> AxiomGT1.snp-posteriors.txt
            else
                sed '/^#/ d'$posteriors_file | sed -n '1!p' >> AxiomGT1.snp-posteriors.txt
            fi
            i=$i+1
        done
        i=0
        for confidences_file in ~{confidences_files} ; do
            if $i=0
            then
                cat $confidences_file >> AxiomGT1.confidences.txt
            else
                sed '/^#/ d'$confidences_file | sed -n '1!p' >> AxiomGT1.confidences.txt
            fi
            i=$i+1
        done
    >>>

    output {
        File report_file = "AxiomGT1.report.txt"
        File calls_file = "AxiomGT1.calls.txt"
        File posteriors_file = "AxiomGT1.snp-posteriors.txt"
        File summary_file = "AxiomGT1.summary.txt"
        File confidences_file = "AxiomGT1.confidences.txt"
    }
}



task SNPolisher {
    input {
        File posterior_file
        File calls_file
        File report_file
        File summary_file
        File library_files_zip
        File? ps_list_file
        String species_type
        String docker_image = "apt/2.11.0:latest"

    }

    meta {
        description: "Ps_metrics and Ps_Classification"
    }

    parameter_meta {
        posterior_file: {
            description: "AxiomGT1.snp-psoteriors.txt format file.",
            extension: ".txt"
        }
        calls_file: {
            description: "AxiomGT1.calls.txt format file.",
            extension: ".txt"
        }
        report_file: {
            description: "AxiomGT1.report.txt format file.",
            extension: ".txt"
        }
        summary_file: {
            description: "AxiomGT1.summary.txt format file.",
            extension: ".txt"
        }
        library_files_zip: {
            description: "Zip archive of Axiom Library Files in root.",
            extension: ".zip"
        }
        ps_list_file: {
            description: "ProbeSet List format file.",
            extension: ".txt, .ps"
        }
        species_type : "Ps_classification mode: one of 'human', 'polyploid' or 'diploid'"
        docker_image: "Docker image to use"
    }

    command <<<
        set -uexo pipefail
        unzip ~{library_files_zip} -d library_files
        additional_args=""
        special_snps_file=$(find library_files -name *.specialSNPs)
        if [  ! -z $special_snps_file ]
        then
            additional_args="${additional_args} --special-snps $special_snps_file "
        fi
        if [ ! -z ~{ps_list_file} ]
        then
            additional_args="${additional_args} --pid-file ~{ps_list_file} "
        fi
        ps2snp_file=$(find library_files -name *.ps2snp_map.ps)
        ps-metrics --posterior-file ~{posterior_file} --call-file ~{calls_file} --report-file ~{report_file} --summary-file ~{summary_file} --metrics-file metrics.txt --output-dir . $additional_args
        ps-classification --species-type ~{species_type} --metrics-file metrics.txt --ps2snp-file $ps2snp_file --output-dir .

    >>>

    runtime {
    docker: docker_image
    cpu: "4"
    memory: "2 GB"
    disks: "local-disk 20 SSD"
    }

    output {
        File metrics_file = "metrics.txt"
        File performance_file = "Ps.performance.txt"
        File phr_ps_file = "PolyHighResolution.ps"
        File nmh_ps_file = "NoMinorHom.ps"
        File mhr_ps_file = "MonoHighResolution.ps"
        File crbt_ps_file = "CallRateBelowThreshold.ps"
        File otv_ps_file = "OffTargetVariant.ps"
        File other_ps_file = "Other.ps"
        File recommended_ps_file = "Recommended.ps"
    }
}

task FormatResultVCF {
    input {
        File calls_file
        File annotation_file
        String vcf_file = "output.vcf"
        File? snp_list_file
        File? sample_filter_file
        File? alternate_probeset_ids
        File? sample_attributes_file
        File? performance_file
        File? additional_snp_information_file
        Boolean export_alternate_sample_names = false
        String SNP_identifier_column = "ProbeSet_ID"
        Boolean export_confidence = false
        Boolean export_log_ratio  = false
        Boolean export_strength = false
        Boolean export_allele_signals = false
        Boolean export_chr_shortname = false
        Boolean export_single_samples = false
        String  call_format = "call_code"
        String? export_basecall_otv = "OTV"
        Boolean enable_divider = true
        String docker_image = "apt/2.11.0:latest"
    }

    meta {
        description: "Format Axiom genotyes into VCF"
    }

    parameter_meta {
        calls_file: {
            description: "AxiomGT1.calls.txt format file.",
            extension: ".txt"
        }
        annotation_file: {
            description: "Array type specific annotation database.",
            extension: ".db"
        }
        vcf_file: "Output file name."
        snp_list_file: {
            description: "File containing list of selected SNP's for export.",
            extension: ".txt, .ps"
        }
        sample_filter_file: {
            description: "List of sample names to filter for export. Generated by user or AxAS. Samples must exist in batch folder. Single column with header of 'cel_files' and sample names only, no paths.",
            extension: ".txt"
        }
        snp_list_file: {
            description: "File containing list of selected SNP's for export.",
            extension: ".txt, .ps"
        }
        alternate_probeset_ids: {
            description: "File with alternate probeset ids.",
            extension: ".txt, .ps"
        }
        sample_attributes_file: {
            description: "Sample attributes file in IGV format. Expected two header columns: [Sample Filename] and [Alternate Sample Name].",
            extension: ".txt"
        }
        sample_filter_file: {
            description: "List of sample names to filter for export. Single column with header of 'cel_files' and sample names only, no paths.",
            extension: ".txt"
        }
        performance_file: {
            description: "Performance file output from SNPolisher.",
            extension: ".txt"
        }
        additional_snp_information_file: {
            description: "TSV file with additional SNP information.",
            extension: ".txt"
        }
        export_alternate_sample_names: "Must be use in conjunction with sample_attributes_file that contains [Alternate Sample Name] column name."
        SNP_identifier_column: "Column name to be used as snp identifier for export. Must be one of annotation columns, e.g. {Affy_SNP_ID, dbSNP_RS_ID}."
        export_confidence: "Turn on/off exporting of confidence data"
        export_log_ratio: "Turn on/off exporting of log2 ratio (MvA) and contrast (CES)"
        export_strength: "Turn on/off exporting of strength (MvA) and size (CES)"
        export_allele_signals: "Turn on/off exporting of strength data"
        export_chr_shortname: "Use chromosome shortname in annotation sqlite db if available."
        export_single_samples: "One sample per file"
        call_format: "Sets format of export calls. Available formats: 'call_code' {AA/AB/BB} or 'base_call' {CC/CT/TT} or 'translated' {0/1/2/-1}."
        export_basecall_otv: "Use in conjunction with '--export-call-format base_call' to make a distinction between NoCall and OTV when exporting using AxiomGT1.calls.txt. Both will be replaced with '---' per DIR specification if this parameter is not supplied. (ex: OTV)"
        enable_divider: "Enable divider '/' between alleles"
        docker_image: "Docker image to use"
    }

    command <<<
        set -uexo pipefail
        arg_string="--calls-file ~{calls_file} --annotation-file ~{annotation_file}"
        arg_string="$arg_string ~{if(defined(snp_list_file)) then ("--snp-list-file " + snp_list_file) else ("")}"
        arg_string="$arg_string ~{if(defined(sample_filter_file)) then ("--sample-filter-file " + sample_filter_file) else ("")}"
        arg_string="$arg_string ~{if(defined(alternate_probeset_ids)) then ("--export-alternate-probeset-ids " + alternate_probeset_ids) else ("")}"
        arg_string="$arg_string ~{if(defined(sample_attributes_file)) then ("--sample-attributes-file " + sample_attributes_file) else ("")}"
        arg_string="$arg_string ~{if(defined(performance_file)) then ("--performance-file " + performance_file) else ("")}"
        arg_string="$arg_string ~{if(defined(additional_snp_information_file)) then ("--additional-snp-information-file " + additional_snp_information_file) else ("")}"
        arg_string="$arg_string ~{if(defined(export_basecall_otv)) then ("--export-basecall-otv " + export_basecall_otv) else ("")}"
        arg_string="$arg_string --export-alternate-sample-names ~{export_alternate_sample_names} "\
        "--snp-identifier-column ~{SNP_identifier_column} --export-confidence ~{export_confidence} "\
        "--export-log-ratio ~{export_log_ratio} --export-strength ~{export_strength} "\
        "--export-allele-signals ~{export_allele_signals} --export-chr-shortname ~{export_chr_shortname} "\
        "--export-single-samples ~{export_single_samples} --export-call-format ~{call_format} --enable-divider ~{enable_divider} "\
        "--export-vcf-file ~{vcf_file}"
        apt-format-result $arg_string
    >>>

    runtime {
    docker: docker_image
    cpu: "4"
    memory: "2 GB"
    disks: "local-disk 20 SSD"
    }

    output{
        File vcf_file = vcf_file
    }
}

task Package {
    input{
        Float blob_format_version = 2.000000
        Boolean create_multi_blob = true
        String species = "Human"
        File report_file
        File posteriors_file
        File calls_file
        File geno_qc_results_file
        File performance_file
        Int samples_per_chunk = 200
        String workflow_type = "probeset_genotyping"
        String? analysis_category
        File? multi_snp_posteriors_file
        String batch_name
        String docker_image = "apt/2.11.0:latest"
    }

    meta {
        description: "Format APT output into an Axiom Analysis Suite proejct folder"
    }

    parameter_meta {
        blob_format_version: "Blob format version for storing genotyping result."
        create_multi_blob: "Use this option to create multiallele genotyping blob using format version 2.0."
        species : "Ps_classification mode: one of 'Human', 'Polyploid' or 'Diploid'"

        report_file: {
            description: "AxiomGT1.report.txt format file.",
            extension: ".txt"
        }
        posteriors_file: {
            description: "AxiomGT1.snp-posteriors.txt format file.",
            extension: ".txt"
        }
        calls_file: {
            description: "AxiomGT1.calls.txt format file.",
            extension: ".txt"
        }
        geno_qc_results_file: {
            description: "Result file of apt-geno-qc.",
            extension: ".txt"
        }
        performance_file: {
            description: "Performance file output from SNPolisher.",
            extension: ".txt"
        }
        samples_per_chunk: "Number of samples to be processed per chunk due to memory limitation."
        workflow_type: "Choose analysis workflow type for AxAS package: 'probeset_genotyping', 'automated_qc' or 'summary_only'."
        analysis_category: "Choose analysis category for multiallele AxAS package. 'cn_gt' for PharmacoScan, 'cn_gt_2' for CarrierScan."
        multi_snp_posteriors_file: "Full path to AxiomGT1.snp-posteriors.multi.txt"
        batch_name: "Name of zipped project folder"
        docker_image: "Docker image to use"

    }



    command <<<
        set -uexo pipefail
        mkdir data
        arg_string="--blob-format-version ~{blob_format_version} --create-multi-blob ~{create_multi_blob} "\
        "--species ~{species} --report-txt-file ~{report_file} --snp-posteriors-file ~{posteriors_file} "\
        "--geno-qc-res-file ~{geno_qc_results_file} --performance-file ~{performance_file} "\
        "--samples-per-chunk ~{samples_per_chunk} --batch-folder ~{batch_name} --genotype-data-dir data"
        arg_string="$arg_string ~{if(defined(analysis_category)) then ("--analysis-category " + analysis_category) else ("")}"
        arg_string="$arg_string ~{if(defined(multi_snp_posteriors_file)) then ("--multi-snp-posteriors-file " + multi_snp_posteriors_file) else ("")}"
        apt-package-util $arg_string
        zip -r ~{batch_name}.zip ~{batch_name}
    >>>

    runtime {
    docker: docker_image
    cpu: "4"
    memory: "2 GB"
    disks: "local-disk 20 SSD"
    }

    output {
        File axas_project_zip_file = batch_name + ".zip"
    }
}

task BatchReport {
    input {
        String? batch_name
        File geno_qc_results_file
        File step1_report_file
        File genotyping_report_file
        File performance_file
        File script_file
        File template_file
        File css_file
        String docker_image = "dxaxiom/1.0.0:latest"
    }

    meta {
        description: "Generate a PDF report of Axiom Batch, Plate and Sample QC."
    }

    parameter_meta {
        batch_name: "Name of"
        geno_qc_results_file: {
            description: "Result file of apt-geno-qc.",
            extension: ".txt"
        }
        step1_report_file: {
            description: "AxiomGT1.report.txt format file from Step1 genotyping.",
            extension: ".txt"
        }
        genotyping_report_file: {
            description: "AxiomGT1.report.txt format file from Step2 genotyping",
            extension: ".txt"
        }
        performance_file: {
            description: "Performance file output from SNPolisher.",
            extension: ".txt"
        }
        script_file: {
            description: "Report generating script.",
            extension: ".py"
        }
        template_file: {
            description: "HTML template file.",
            extension: ".html"
        }
        css_file: {
            description: "CSS file used to style intermediate HTML and the PDF.",
            extension: ".css"
        }
        docker_image: "Docker image to use."
    }

    String actual_batch_name = select_first([batch_name, '""'])
    command <<<
        set -uexo pipefail
        python3 ~{script_file} -n ~{actual_batch_name} -d ~{geno_qc_results_file} -q ~{step1_report_file} -g ~{genotyping_report_file} -p ~{performance_file} -t ~{template_file} -c ~{css_file}

    >>>

    runtime {
    docker: docker_image
    cpu: "2"
    memory: "2 GB"
    disks: "local-disk 20 SSD"
    }

    output {
        File batch_report_file = batch_name + '_report.pdf'
    }

}


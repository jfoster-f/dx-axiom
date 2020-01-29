version 1.0

task Dqc {
    input {
        Array[File] cel_files
        File? cel_files_file
        File library_files_zip
        String? xml_file
        Float dqc_threshold = 0.82
        String docker_image = "apt/2.11.0:latest"
        String? output_prefix
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
        dqc_threshold: "Theshold below which a CEL file fails DQC."
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
    cpu: "8"
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
        String? output_prefix
    }

    Float actual_cr_fail_threshold = select_first([cr_fail_threshold, cr_pass_threshold])


    meta {
        description: "Step1 Genotyping of DQC passing cel_file with apt-genotype-axiom."
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
        cr_fail_threshold: "Theshold below which a CEL file fails Call Rate."
        cr_pass_threshold: "Theshold above which a CEL file passes Call Rate."
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
    cpu: "8"
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
        File? priors
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
        cr_pass_threshold: "Theshold above which a CEL file passes Call Rate."
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
        if [ ! -z ~{priors} ]
        then
            additional_args="${additional_args} --snp-priors-input-file ~{priors} "
        fi
        apt-genotype-axiom --analysis-files-path library_files --arg-file $xml_file --cel-files $cel_files_file --log-file apt-genotype-axiom.log --dual-channel-normalization true --allele-summaries true --snp-posteriors-output true $additional_args
        grep -v ^# AxiomGT1.report.txt | awk '{print $1 $4}' > report_simple.txt
        cat report_simple.txt | awk '$2 >= ~{actual_cr_pass_threshold} {print $1}' > passing_cel_files.txt

    >>>

    runtime {
    docker: docker_image
    cpu: "8"
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


task SNPolisher {
    input {
        File posterior_file
        File calls_file
        File report_file
        File summary_file
        File library_files_zip
        File? ps_list_file
        String species_type
    }

    meta {
        description: "Ps_metrics and Ps_Classification"
    }

    parameter_meta {
        posterior_file: "AxiomGT1.snp-psoteriors.txt format file."
        calls_file: "AxiomGT1.calls.txt format file."
    }

    command <<<
        set -uexo pipefail
        unzip ~{library_files_zip} -d library_files
        additional_args=""
        special_snps_file=$(find library_files -name *.specialSNPs)
        if [  ! -z $special_snps_file ]
        then
            additional_args="${additional_args} --special_snps $special_snps_file "
        fi
        if [ ! -z ~{ps_list_file} ]
        then
            additional_args="${additional_args} --pid-file ~{ps_list_file} "
        fi
        ps2snp_file=$(find library_files -name *.ps2snp_map.ps)
        echo $(ls /usr/local/bin)
        ps-metrics --posterior-file ~{posterior_file} --call-file ~{calls_file} --report-file ~{report_file} --summary_file ~{summary_file} --metrics-file metrics.txt $additional_args
        ps-classification --species-type ~{species_type} --metrics-file metrics.txt --ps2snp-file $ps2snp_file --output-dir .

    >>>

    output {
        File metrics_file = "metrics.txt"
        File ps_performance_file = "Ps.performance.txt"
    }


}

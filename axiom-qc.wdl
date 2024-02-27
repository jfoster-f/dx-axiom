version 1.0

import "axiom.wdl" as axiom

workflow Qc {
    input {
        Array[File] cel_files
        File library_files_zip
        Float dqc_threshold = 0.82
        Int max_threads = 0
    }

    meta {
        description: "Perform Axiom QC as per the Best Practices Workflow: DQC -> Step1 Genotyping"
    }

    parameter_meta {
        cel_files: {
                       description: "Set of 1 of more CEL files to be analysed.",
                       extension: ".CEL"
                   }
        library_files_zip: {
                               description: "Zip archive of Axiom Library Files in root.",
                               extension: ".zip"
                           }
        dqc_threshold: "Theshold below which a CEL file fails DQC."
        qccr_fail_threshold: "Theshold below which a CEL file fails QC Call Rate."
        qccr_pass_threshold: "Theshold above which a CEL file passes QC Call Rate."
    }

    call axiom.geno_qc_axiom {
        input:
            cel_files = cel_files,
            library_files_zip = library_files_zip,
            arg_file = "Axiom_PMRA.r3.apt-geno-qc.AxiomQC1.xml",
            dqc_threshold = dqc_threshold,
            max_threads = max_threads
    }

    call axiom.step1_genotype {
        input:
            cel_files = geno_qc_axiom.passing_cel_files,
            library_files_zip = library_files_zip,
            arg_file = "Axiom_PMRA_96orMore_Step1.r3.apt-genotype-axiom.AxiomGT1.apt2.xml",
    }

    output {
        File geno_qc_report_file = geno_qc_axiom.report_file
        File genotype_report_file = step1_genotype.genotype_report_file
        File passing_cel_files = step1_genotype.passing_cel_files_file
        File batch_folder_zip = step1_genotype.batch_folder_zip
    }
}
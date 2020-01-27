version 1.0

import "axiom.wdl" as axiom

workflow qc {
 input {
    Array[File] cel_files
    File library_files_zip
    Float dqc_threshold = 0.82
    Float qccr_fail_threshold = 97.0
    Float qccr_pass_threshold = 97.0
    String docker_image = "apt/2.11.0:latest"
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
    docker_image: "Docker image to use"
 }

 call axiom.Dqc{
    input:
       cel_files = cel_files,
       library_files_zip = library_files_zip,
       dqc_threshold = dqc_threshold,
       docker_image = docker_image
 }

 call axiom.Step1Genotype {
    input:
        cel_files = cel_files,
        cel_files_file = Dqc.passing_cel_files_file,
        library_files_zip = library_files_zip,
        cr_fail_threshold = qccr_fail_threshold,
        cr_pass_threshold = qccr_pass_threshold,
        docker_image = docker_image
 }

 output {
    File passing_cel_files_file = Step1Genotype.passing_cel_files_file
    File failing_cel_files_file = Step1Genotype.failing_cel_files_file
    File rescuable_cel_files_file = Step1Genotype.rescuable_cel_files_file
    File dqc_file = Dqc.report_file
    File report_file = Step1Genotype.report_file
 }

}
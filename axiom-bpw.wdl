version 1.0

import "axiom.wdl" as axiom

workflow bpw {
 input {
    Array[File] cel_files
    File library_files_zip
    Float dqc_threshold = 0.82
    Float qccr_fail_threshold = 97.0
    Float qccr_pass_threshold = 97.0
    String? priors_filename
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

 call axiom.dqc{
    input:
       cel_files = cel_files,
       library_files_zip = library_files_zip,
       dqc_threshold = dqc_threshold,
       docker_image = docker_image
 }

 call axiom.step1_genotype {
    input:
        cel_files = cel_files,
        cel_files_file = dqc.passing_cel_files_file,
        library_files_zip = library_files_zip,
        qccr_fail_threshold = qccr_fail_threshold,
        qccr_pass_threshold = qccr_pass_threshold,
        docker_image = docker_image
 }

 call axiom.step2_genotype as genotype{
    input:
        cel_files = cel_files,
        cel_files_file = step1_genotype.passing_cel_files_file,
        library_files_zip = library_files_zip,
        rescue_genotyping = false,
        docker_image = docker_image
 }

 call axiom.step2_genotype as rescue{
    input:
        cel_files = cel_files,
        cel_files_file = step1_genotype.rescueable_cel_files_file,
        library_files_zip = library_files_zip,
        priors = genotype.posteriors_file,
        rescue_genotyping = true,
        docker_image = docker_image
 }

 output {
    File dqc_file = dqc.report_file
    File dqc_passing_cel_files_file = dqc.passing_cel_files_file
    File dqc_failing_cel_files_file = dqc.failing_cel_files_file
    File step1_passing_cel_files_file = step1_genotype.passing_cel_files_file
    File step1_failing_cel_files_file = step1_genotype.failing_cel_files_file
    File step1_rescuable_cel_files_file = step1_genotype.rescuable_cel_files_file
    File step1_report_file = step1_genotype.report_file
    File genotyping_report_file = genotype.report_file
    File genotyping_calls_file = genotype.calls_file
    File genotyping_posteriors_file = genotype.posteriors_file
    File genotyping_summary_file = genotype.summary_file
    File genotyping_confidences_file = genotype.confidences_file
    File genotyping_passing_cel_files_file = genotype.passing_cel_files_file
    File rescue_report_file = genotype.report_file
    File rescue_calls_file = genotype.calls_file
    File rescue_posteriors_file = genotype.posteriors_file
    File rescue_summary_file = genotype.summary_file
    File rescue_confidences_file = genotype.confidences_file
    File rescue_passing_cel_files_file = genotype.passing_cel_files_file
 }

}
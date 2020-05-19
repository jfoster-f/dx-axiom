version 1.0

import "axiom.wdl" as axiom

workflow LivingDNA {
 input {
    Array[File] cel_files
    File library_files_zip
    File annotation_file
    File script_file
    File template_file
    File css_file
    Float dqc_threshold = 0.82
    Float qccr_fail_threshold = 97.0
    Float qccr_pass_threshold = 97.0
    String? priors_filename
    String? batch_name
    String apt_docker_image = "apt/2.11.0:latest"
    String report_docker_image = "dxaxiom/1.0.0:latest"
 }

 meta {
    description: "Implement the Axiom Best Practices in the LivingDNA context"
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

    apt_docker_image: "Docker image to use"
    report_docker_image: "Docker image to use"
 }

 call axiom.Dqc{
    input:
       cel_files = cel_files,
       library_files_zip = library_files_zip,
       dqc_threshold = dqc_threshold,
       docker_image = apt_docker_image
 }

 call axiom.Step1Genotype {
    input:
        cel_files = cel_files,
        cel_files_file = Dqc.passing_cel_files_file,
        library_files_zip = library_files_zip,
        cr_fail_threshold = qccr_fail_threshold,
        cr_pass_threshold = qccr_pass_threshold,
        docker_image = apt_docker_image
 }

 call axiom.Step2Genotype as genotype{
    input:
        cel_files = cel_files,
        cel_files_file = Step1Genotype.passing_cel_files_file,
        library_files_zip = library_files_zip,
        rescue_genotyping = false,
        docker_image = apt_docker_image
 }


 if(length(read_lines(Step1Genotype.rescuable_cel_files_file)) > 1) {
    call axiom.Step2Genotype as rescue{
        input:
            cel_files = cel_files,
            cel_files_file = Step1Genotype.rescuable_cel_files_file,
            library_files_zip = library_files_zip,
            priors_file = genotype.posteriors_file,
            rescue_genotyping = true,
            docker_image = apt_docker_image
    }
 }

 call axiom.SNPolisher {
    input:
        posterior_file = genotype.posteriors_file,
        calls_file = genotype.calls_file,
        report_file = genotype.report_file,
        summary_file = genotype.summary_file,
        library_files_zip = library_files_zip,
        species_type = "human",
        docker_image = apt_docker_image
 }

 call axiom.FormatResultVCF as vcf_pass {
    input:
        calls_file = genotype.calls_file,
        annotation_file = annotation_file,
        performance_file = SNPolisher.performance_file,
        docker_image = apt_docker_image

 }

 if(length(read_lines(Step1Genotype.rescuable_cel_files_file)) > 1) {
 call axiom.FormatResultVCF as vcf_rescue {
    input:
        calls_file = select_first([rescue.calls_file]),
        annotation_file = annotation_file,
        performance_file = SNPolisher.performance_file,
        docker_image = apt_docker_image

 }
 }

 call axiom.BatchReport {
    input:
        geno_qc_results_file = Dqc.report_file,
        step1_report_file = Step1Genotype.report_file,
        genotyping_report_file = genotype.report_file,
        performance_file = SNPolisher.performance_file,
        script_file = script_file,
        template_file = template_file,
        css_file = css_file,
        batch_name = batch_name,
        docker_image = report_docker_image

 }

 output {
    File geno_qc_results_file = Dqc.report_file
    File dqc_passing_cel_files_file = Dqc.passing_cel_files_file
    File dqc_failing_cel_files_file = Dqc.failing_cel_files_file
    File step1_passing_cel_files_file = Step1Genotype.passing_cel_files_file
    File step1_failing_cel_files_file = Step1Genotype.failing_cel_files_file
    File step1_rescuable_cel_files_file = Step1Genotype.rescuable_cel_files_file
    File step1_report_file = Step1Genotype.report_file
    File genotyping_report_file = genotype.report_file
    File genotyping_calls_file = genotype.calls_file
    File genotyping_posteriors_file = genotype.posteriors_file
    File genotyping_summary_file = genotype.summary_file
    File genotyping_confidences_file = genotype.confidences_file
    File genotyping_passing_cel_files_file = genotype.passing_cel_files_file
    File? rescue_report_file = rescue.report_file
    File? rescue_calls_file = rescue.calls_file
    File? rescue_posteriors_file = rescue.posteriors_file
    File? rescue_summary_file = rescue.summary_file
    File? rescue_confidences_file = rescue.confidences_file
    File? rescue_passing_cel_files_file = genotype.passing_cel_files_file
    File metrics_file = SNPolisher.metrics_file
    File performance_file = SNPolisher.performance_file
    File vcf_pass_file = vcf_pass.vcf_file
    File? vcf_rescue_file = vcf_rescue.vcf_file
    File batch_report_file = BatchReport.batch_report_file
 }

}
version 1.0

import "axiom.wdl" as axiom

workflow BatchReportTest {
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

    call axiom.BatchReport{
        input:
            batch_name = batch_name,
            geno_qc_results_file = geno_qc_results_file,
            step1_report_file = step1_report_file,
            genotyping_report_file = genotyping_report_file,
            performance_file = performance_file,
            script_file = script_file,
            template_file = template_file,
            css_file = css_file,
            docker_image = docker_image,
    }

    output {
        File metrics_file = BatchReport.batch_report_file
    }
}
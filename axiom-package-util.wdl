version 1.0

import "axiom.wdl" as axiom

workflow PackageUtilTest {
input {
        File report_file
        File posteriors_file
        File geno_qc_results_file
        File performance_file
        String output_name
        String docker_image = "apt/2.11.0:latest"

    }

    call axiom.Package{
        input:
            report_file = report_file,
            posteriors_file = posteriors_file,
            geno_qc_results_file = geno_qc_results_file,
            performance_file = performance_file,
            output_name = output_name,
            docker_image = docker_image
    }

    output {
        File axas_project_zip_file = Package.axas_project_zip_file
    }
}
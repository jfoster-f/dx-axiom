version 1.0

import "axiom.wdl" as axiom

workflow SNPolisherTest {
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

    call axiom.SNPolisher{
        input:
            posterior_file = posterior_file,
            calls_file = calls_file,
            report_file = report_file,
            summary_file = summary_file,
            library_files_zip = library_files_zip,
            species_type = species_type,
            docker_image = docker_image
    }

    output {
        File metrics_file = "metrics.txt"
        File ps_performance_file = "Ps.performance.txt"
    }
}
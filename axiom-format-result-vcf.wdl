version 1.0

import "axiom.wdl" as axiom

workflow FormatResultVCFTest {
input {
        File calls_file
        File annotation_file
        File performance_file
        String docker_image = "apt/2.11.0:latest"

    }

    call axiom.FormatResultVCF{
        input:
            calls_file = calls_file,
            annotation_file = annotation_file,
            performance_file = performance_file,
            docker_image = docker_image
    }

    output {
        File vcf_file = FormatResultVCF.vcf_file
    }
}
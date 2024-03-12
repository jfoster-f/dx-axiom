version 1.0

task ps_visualization {
    input {
        Int n_plots = 500
        File polyhighresolution_file
        File nominorhom_file
        File monohighresolution_file
        File callratebelowthreshold_file
        File offtargetvarant_file
        File other_file
        File call_file
        File summary_file
        File posterior_file
        File confidence_file
        File special_snps_file
        String optional_args = ""
    }

    meta {
        description: "Ps-visualization"
    }

    parameter_meta {
        posterior_file: "Full path name of posterior file. File must exist and file is required."
        call_file: "Full path name of calls file. If the chp-files parameter is not used, file must exist and file is required."
        pid_file: "Full path name of pid file."
        summary_file: "Full path name of summary file. Can accept input summary files in the txt and a5 (hdf5) format. If the batch folder option is not used with CN data, file must exist and file is required for CN0 mean calculation."
        special_snps: "Full path name of specialSnp file. With CN data, file must exist and is required for hemizygous calculations."
        report_file: "Full path name of report file. File is required for SSP metrics calculation."

    }

    command <<<
        set -uexo pipefail
        Rscript --vanilla ps_visualization.R 500 ~{polyhighresolution_file} ~{nominorhom_file} ~{monohighresolution_file} ~{callratebelowthreshold_file} ~{offtargetvarant_file} ~{other_file} ~{call_file} ~{summary_file} ~{posterior_file} ~{confidence_file} ~{special_snps_file} ~{optional_args}
    >>>

    runtime {
        docker: "dx://file-GgKGbVQ08vJZG4gXXfK6jzVb"
        dx_instance_type: "mem1_ssd1_v2_x2"
    }

    output {
        File polyhighresolution_plots_file = "PolyHighResolution.pdf"
        File nominorhom_plots_file = "NoMinorHom.pdf"
        File monohighresolution_plots_file = "MonoHighResolution.pdf"
        File callratebelowthreshold_plots_file = "CallRateBelowThreshold.pdf"
        File offtargetvarant_plots_file = "OffTargetVariant.pdf"
        File other_file_plots_file = "Other.pdf"
    }
}
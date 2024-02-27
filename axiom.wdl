version 1.0

task geno_qc_axiom {
    input {
        Array[File] cel_files
        File library_files_zip
        Boolean program_version = false
        Boolean user_help = false
        String? log_file
        String? console_add_select
        String? console_add_neg_select
        String? arg_file
        Boolean check_param = false
        Int max_threads = 0
        String out_file = "dqc_report.txt"
        String? out_dir
        String? temp_dir
        String analysis_files_path = "library_files"
        String chip_type = "apt2-genotype"
        Boolean force = true
        String analysis_name = "apt-geno-qc-axiom"
        File? x_probes_file
        File? y_probes_file
        File? w_probes_file
        File? z_probes_file
        File? sketch_target_input_file
        Float sketch_target_scale_value = 1000.0
        Boolean sketch_target_use_avg = true
        Boolean dual_channel_target_sketch = true
        Boolean dual_channel_normalization = true
        File? qca_file
        File? qcc_file
        File? reagent_kit_discriminator
        File? cdf_file
        File? probe_class_file
        Int? sketch_size
        Float igender_female_threshold = 0.48
        Float igender_male_threshold = 0.7
        Float dqc_threshold = 0.82
        String docker_image = "dnanexus/apt:2.11.8"
    }

    meta {
        description: "Process one or more CEL files with apt-geno-qc-axiom."
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
        program_version: "Display the version info for this program."
        user_help: "Display help intended for end-users."
        log_file: "The name of the log file.  Defaults to 'PROGRAMNAME-NUMBER.log'."
        console_add_select: "Add selectors for console messages. e.g. to include all debug messages: --console-add-select debug to include all messages of level 3 or higher: --console-add-select '*:3'"
        console_add_neg_select: "Add selectors to be excluded from console messages. e.g. to exclude all warning messages and errors summary: --console-add-neg-select WARNING,summary"
        arg_file: "Read arguments from this file. File should be a valid XML file, and should contain elements of the form <Parameter name='PARAMETER-NAME analysis='NODE-NAME' currentValue='VALUE' />."
        check_param: "Stop the program after the command parameters have been checked."
        max_threads: "Maximum thread count (0 = unlimited threads); Default = number of CPUs detected default value: '0'"
        out_file: "Name to use for the output file."
        out_dir: "The output directory for result files."
        temp_dir: "The output directory for temporary files."
        analysis_files_path: "Default directory to search for analysis library files"
        chip_type: "Text identifier for chip. default value: 'apt2-genotype'"
        force:  "Force the files to process regardless of array type. default value: 'True'"
        analysis_name: "Name to prepend to output files. default value: 'apt-geno-qc-axiom'"
        x_probes_file: "The file that identifies the X chromosome probe ids."
        y_probes_file: "The file that identifies the X chromosome probe ids."
        w_probes_file: "The file that identifies the X chromosome probe ids."
        z_probes_file: "The file that identifies the X chromosome probe ids."
        sketch_target_input_file: "Name of the file containing sketch to use."
        sketch_target_scale_value: "Target to scale the sketch to default value: '1000.000000'"
        sketch_target_use_avg: "When there is a range of identical intensities, use the average of the corresponding target sketch values. default value: 'True'"
        dual_channel_target_sketch: "Create sketches from separate channels (AT/GC) default value: 'True'"
        dual_channel_normalization: "Use dual channel normalization. default value: 'True'"
        qca_file: "File defining QC analysis methods."
        qcc_file: "File defining QC probesets."
        reagent_kit_discriminator: "File containing list of probesets with PC1s and means to use for classifying the reagent kits."
        cdf_file: "The CDF input file."
        probe_class_file: "File containing probe_id (1-based) of probes and a 'class' designation. Used to compute mean probe intensity by class for report file."
        sketch_size: "The sketch size to use."
        igender_female_threshold: "The female threshold to use in the raw intensity gender call. default value: '0.480000'"
        igender_male_threshold: "The male threshold to use in the raw intensity gender call. default value: '0.700000'"
        dqc_threshold: "Theshold below which a CEL file fails DQC."
        docker_image: "Docker image to use"
    }

    command <<<
        set -uexo pipefail
        cmd_string=""
        echo "cel_files" > cel_files.txt
        for FILE in ~{sep=' ' cel_files}; do
        echo $FILE >> cel_files.txt
        done
        cmd_string+=" --cel-files cel_files.txt"
        unzip ~{library_files_zip} -d ~{analysis_files_path}
        mv cel_files.txt ~{analysis_files_path}/
        cmd_string+=" --analysis-files-path ~{analysis_files_path}"
        cmd_string+=~{if program_version then " --version" else ""}
        cmd_string+=~{if user_help then " --user-help" else ""}
        cmd_string+=~{if defined(log_file) then " --log-file " + log_file else ""}
        cmd_string+=~{if defined(console_add_select) then " --console-add-select " + console_add_select else ""}
        cmd_string+=~{if defined(console_add_neg_select) then " --console-add-neg-select " + console_add_neg_select else ""}

        if [ -z ~{arg_file} ]
        then
        arg_file=$(find ~{analysis_files_path} -name *AxiomQC1*)
        else
        arg_file=~{analysis_files_path}/~{arg_file}
        fi
        cmd_string+=" --arg-file ${arg_file}"

        cmd_string+=~{if check_param then " --check-param" else ""}

        if [[ ~{max_threads} -gt 0 ]]
        then
        cmd_string+=" --max-threads ~{max_threads}"
        fi

        cmd_string+=" --out-file ~{out_file}"
        cmd_string+=~{if defined(out_dir) then " --out-dir " + out_dir else ""}
        cmd_string+=~{if defined(temp_dir) then " --temp-dir " + temp_dir else ""}

        if [[  ~{chip_type} != apt2-genotype ]]
        then
        cmd_string+=" --chip-type ~{chip_type}"
        fi

        cmd_string+=~{if force then "" else " --force False"}

        if [[  ~{analysis_name} != apt-geno-qc-axiom ]]
        then
        cmd_string+=" --analysis-name ~{analysis_name}"
        fi

        cmd_string+=~{if defined(x_probes_file) then " --x-probes-file " + x_probes_file else ""}
        cmd_string+=~{if defined(y_probes_file) then " --y-probes-file " + y_probes_file else ""}
        cmd_string+=~{if defined(w_probes_file) then " --w-probes-file " + w_probes_file else ""}
        cmd_string+=~{if defined(z_probes_file) then " --z-probes-file " + z_probes_file else ""}
        cmd_string+=~{if defined(sketch_target_input_file) then " --sketch-target-input-file " + sketch_target_input_file else ""}

        if [[ ~{sketch_target_scale_value} != "1000.0" ]]
        then
        cmd_string+=" --sketch-target-scale-value ~{sketch_target_scale_value}"
        fi

        cmd_string+=~{if sketch_target_use_avg then "" else " --sketch-target-use-avg False"}
        cmd_string+=~{if dual_channel_target_sketch then "" else " --dual-channel-target-sketch False"}
        cmd_string+=~{if dual_channel_normalization then "" else " --dual-channel-normaliztion False"}
        cmd_string+=~{if defined(qca_file) then " --qca-file " + qca_file else ""}
        cmd_string+=~{if defined(qcc_file) then " --qcc-file " + qcc_file else ""}
        cmd_string+=~{if defined(reagent_kit_discriminator) then " --reagent-kit-discriminator " + reagent_kit_discriminator else ""}
        cmd_string+=~{if defined(cdf_file) then " --cdf-file " + cdf_file else ""}
        cmd_string+=~{if defined(probe_class_file) then " --probe-class-file " + probe_class_file else ""}
        cmd_string+=~{if defined(sketch_size) then " --sketch-size  " + sketch_size else ""}

        echo $cmd_string
        apt-geno-qc-axiom ${cmd_string}
        grep -v ^# dqc_report.txt | awk '{print $1 "\t" $18}' > dqc_simple.txt
        tail -n +2 dqc_simple.txt | awk '$2 >= ~{dqc_threshold} {print $1}' > passing_cel_files.txt
        tail -n +2 dqc_simple.txt | awk '$2 < ~{dqc_threshold} {print $1}' > failing_cel_files.txt

        mkdir -p out/passing_cel_files
        mkdir -p out/failing_cel_files

        for FILE in $(cat passing_cel_files.txt); do
            CEL=$(find /home/dnanexus/inputs -name $FILE)
            echo $CEL
            [[ -f $CEL ]] && mv $CEL out/passing_cel_files
        done

        for FILE in $(cat failing_cel_files.txt); do
            echo $FILE
            CEL=$(find /home/dnanexus/inputs -name $FILE)
            echo $CEL
            [[ -f $CEL ]] && mv $CEL out/failing_cel_files
        done

    >>>

    runtime {
        docker: docker_image
        dx_instance_type: "mem1_ssd1_v2_x4"
    }

    output {
        File report_file = "dqc_report.txt"
        File passing_cel_files_file = "passing_cel_files.txt"
        File failing_cel_files_file = "failing_cel_files.txt"
        Array[File] passing_cel_files = glob("out/passing_cel_files/*")
        Array[File] failing_cel_files = glob("out/failing_cel_files/*")
    }
}

task genotype {
    input {
        Array[File] cel_files
        File? cel_files_file
        File library_files_zip
        Boolean program_version = false
        Boolean user_help = false
        String? log_file
        String? console_add_select
        String? console_add_neg_select
        String? arg_file
        Boolean check_param = false
        Int max_threads = 0
        Boolean delete_temp_files = true
        String? out_dir
        String? temp_dir
        String analysis_files_path = "library_files"
        String batch_folder = "batch_folder"
        String batch_folder_data_dir = "AxiomAnalysisSuiteData"
        Boolean force = true
        String chip_type = "apt2-genotype"
        String analysis_name = "apt-genotype-step1"
        Boolean report = true
        String report_file = "report.txt"
        Boolean summaries_only = false
        File? x_probes_file
        File? y_probes_file
        File? w_probes_file
        File? z_probes_file
        Boolean sketch_target_output = false
        String? sketch_target_output_file
        Boolean dual_channel_target_sketch = true
        File? sketch_target_input_file
        Float sketch_target_scale_value = 0.0
        Boolean sketch_target_use_avg = true
        Boolean dual_channel_normalization = true
        Boolean probabilities_output = false
        Boolean summary_a5_output = false
        Boolean do_rare_het_adjustment = false
        File? rare_het_candidate_file
        Boolean process_multi_alleles = false
        File? probeset_ids
        File? cdf_file
        File? special_snps
        File? snp_specific_param_file
        File? gender_file
        File? inbred_file
        File? hints_file
        Float global_inbred_het_penalty = 0.0
        Float igender_female_threshold = 0.48
        Float igender_male_threshold = 0.7
        Float artifact_reduction_clip = 0.4
        Float artifact_reduction_clip_pvcam = 0.43
        Int artifact_reduction_open = 1
        Int artifact_reduction_close = 3
        Int artifact_reduction_fringe = 2
        Int artifact_reduction_cc = 1
        Boolean artifact_reduction_trustcheck = false
        Boolean artifact_reduction_output_trustcheck = false
        File? raw_gender_write_intensities_node_normalized_intensities_output_file
        Int? sketch_size
        File?  normalization_write_intensities_node_normalized_intensities_output_file
        Float blob_format_version = 2.0
        Int sample_multiplier = 1
        Boolean use_copynumber_call_codes = false
        Boolean allele_summaries = false
        String? allele_summaries_file
        Float background_percentile = 0.1
        Float pedestal = 256.0
        File? genotyping_node_snp_priors_input_file
        Boolean genotyping_node_snp_posteriors_output = false
        String? genotyping_node_snp_posteriors_output_file
        Boolean genotyping_node_table_output = true
        Boolean genotyping_node_a5_tables = false
        String? genotyping_node_calls_file
        String? genotyping_node_confidences_file
        String? genotyping_node_probabilities_file
        Int genotyping_node_probabilities_file_sample_count = 0
        File? genotyping_node_copynumber_probeset_calls_file
        Boolean genotyping_node_copynumber_override_special_snps = false
        Int genotyping_node_brlmmp_HARD = 3
        Float genotyping_node_brlmmp_SB = 0.45
        Int genotyping_node_brlmmp_CM = 1
        Int genotyping_node_brlmmp_bins = 100
        Int genotyping_node_brlmmp_mix = 1
        Float genotyping_node_brlmmp_bic = 2.0
        Float genotyping_node_brlmmp_CSepPen = 0.0
        Float genotyping_node_brlmmp_CSepThr = 16.0
        Float genotyping_node_brlmmp_lambda = 1.0
        Float genotyping_node_brlmmp_wobble = 0.05
        Float genotyping_node_brlmmp_copyqc = 0.0
        Int genotyping_node_brlmmp_copytype = 0
        Float genotyping_node_brlmmp_MS = 0.05
        Float genotyping_node_brlmmp_ocean = 0.0
        Int genotyping_node_brlmmp_clustertype = 1
        Float genotyping_node_brlmmp_IsoHetY = 0.0
        Float genotyping_node_brlmmp_inflatePRA = 0.0
        Float genotyping_node_brlmmp_CP = 16.0
        Boolean genotyping_node_brlmmp_comvar = true
        Float genotyping_node_brlmmp_K = 1.0
        Int genotyping_node_max_rare_het_count = 3
        Float genotyping_node_gc_channel_sci_threshold = 0.39
        Float genotyping_node_at_channel_sci_threshold = 0.39
        Float genotyping_node_major_hom_relative_min_percent = 80.0
        Int genotyping_node_major_hom_absolute_min_thresh = 15
        File? multi_allele_background_node_snp_priors_input_file
        Boolean multi_allele_background_node_snp_posteriors_output = false
        String? multi_allele_background_node_snp_posteriors_output_file
        Boolean multi_allele_background_node_table_output = true
        Boolean multi_allele_background_node_a5_tables = false
        File? multi_allele_background_node_calls_file
        File? multi_allele_background_node_confidences_file
        File? multi_allele_background_node_copynumber_probeset_calls_file
        Boolean multi_allele_background_node_copynumber_override_special_snps = false
        Int multi_allele_background_node_brlmmp_HARD = 3
        Float multi_allele_background_node_brlmmp_SB = 0.45
        Int multi_allele_background_node_brlmmp_CM = 1
        Int multi_allele_background_node_brlmmp_bins = 100
        Int multi_allele_background_node_brlmmp_mix = 1
        Float multi_allele_background_node_brlmmp_bic = 2.0
        Float multi_allele_background_node_brlmmp_CSepPen = 0.0
        Float multi_allele_background_node_brlmmp_CSepThr = 16.0
        Float multi_allele_background_node_brlmmp_lambda = 1.0
        Float multi_allele_background_node_brlmmp_wobble = 0.05
        Float multi_allele_background_node_brlmmp_copyqc = 0.0
        Int multi_allele_background_node_brlmmp_copytype = 0
        Float multi_allele_background_node_brlmmp_MS = 0.05
        Float multi_allele_background_node_brlmmp_ocean = 0.0
        Int multi_allele_background_node_brlmmp_clustertype = 1
        String multi_allele_background_node_brlmmp_transform = "mva"
        Float multi_allele_background_node_brlmmp_IsoHetY = 0.0
        Float multi_allele_background_node_brlmmp_inflatePRA = 0.0
        Float multi_allele_background_node_brlmmp_CP = 16.0
        Boolean multi_allele_background_node_brlmmp_comvar = true
        Float multi_allele_background_node_brlmmp_K = 1.0
        Int multi_allele_background_node_max_rare_het_count = 3
        Float multi_allele_background_node_gc_channel_sci_threshold = 0.39
        Float multi_allele_background_node_at_channel_sci_threshold = 0.39
        Float multi_allele_background_node_major_hom_relative_min_percent = 80.0
        Int multi_allele_background_node_major_hom_absolute_min_thresh = 15
        File? multi_allele_pairwise_node_snp_priors_input_file
        Boolean multi_allele_pairwise_node_snp_posteriors_output = false
        String? multi_allele_pairwise_node_snp_posteriors_output_file
        Boolean multi_allele_pairwise_node_table_output = true
        Boolean multi_allele_pairwise_node_a5_tables = false
        File? multi_allele_pairwise_node_calls_file
        File? multi_allele_pairwise_node_confidences_file
        File? multi_allele_pairwise_node_copynumber_probeset_calls_file
        Boolean multi_allele_pairwise_node_copynumber_override_special_snps = false
        Int multi_allele_pairwise_node_brlmmp_HARD = 3
        Float multi_allele_pairwise_node_brlmmp_SB = 0.45
        Int multi_allele_pairwise_node_brlmmp_CM = 1
        Int multi_allele_pairwise_node_brlmmp_bins = 100
        Int multi_allele_pairwise_node_brlmmp_mix = 1
        Float multi_allele_pairwise_node_brlmmp_bic = 2.0
        Float multi_allele_pairwise_node_brlmmp_CSepPen = 0.0
        Float multi_allele_pairwise_node_brlmmp_CSepThr = 16.0
        Float multi_allele_pairwise_node_brlmmp_lambda = 1.0
        Float multi_allele_pairwise_node_brlmmp_wobble = 0.05
        Float multi_allele_pairwise_node_brlmmp_copyqc = 0.0
        Int multi_allele_pairwise_node_brlmmp_copytype = 0
        Float multi_allele_pairwise_node_brlmmp_MS = 0.05
        Float multi_allele_pairwise_node_brlmmp_ocean = 0.0
        Int multi_allele_pairwise_node_brlmmp_clustertype = 1
        String multi_allele_pairwise_node_brlmmp_transform = "mva"
        Float multi_allele_pairwise_node_brlmmp_IsoHetY = 0.0
        Float multi_allele_pairwise_node_brlmmp_inflatePRA = 0.0
        Float multi_allele_pairwise_node_brlmmp_CP = 16.0
        Boolean multi_allele_pairwise_node_brlmmp_comvar = true
        Float multi_allele_pairwise_node_brlmmp_K = 1.0
        Int multi_allele_pairwise_node_max_rare_het_count = 3
        Float multi_allele_pairwise_node_gc_channel_sci_threshold = 0.39
        Float multi_allele_pairwise_node_at_channel_sci_threshold = 0.39
        Float multi_allele_pairwise_node_major_hom_relative_min_percent = 80.0
        Float multi_allele_pairwise_node_major_hom_absolute_min_thresh = 15
        Boolean multi_freq_flag = false
        Float multi_inflate_PRA = 0.0
        Float multi_ocean = 0.00001
        Float multi_lambda_P = 0.0
        Float multi_wobble = 0.05
        Float multi_copy_distance_0to1 = 1.5
        Float multi_copy_distance_1to2 = 0.2
        Float multi_shell_barrier_0to1 = 0.05
        Float multi_shell_barrier_1to2 = 0.05
        Float multi_confidence_threshold = 0.15
        File? multi_priors_input_file
        Boolean multi_posteriors_output = false
        String? multi_posteriors_output_file
        Float? cr_fail_threshold
        Float? cr_pass_threshold
        String docker_image = "dnanexus/apt:2.11.8"
    }

    Float actual_cr_fail_threshold = select_first([cr_fail_threshold, cr_pass_threshold])

    meta {
        description: "Step1 Genotyping of DQC passing cel_file with apt-genotype-axiom."
    }
    parameter_meta {

        program_version: "Display the version info for this program."
        user_help: "Display help intended for end_users."
        log_file: "The name of the log file.  Defaults to 'PROGRAMNAME_NUMBER.log’."
        console_add_select: "Add selectors for console messages. e.g. to include all debug messages_ console_add_select debug to include all messages of level 3 or higher_ console_add_select ‘*_3’"
        console_add_neg_select: "Add selectors to be excluded from console messages. e.g. to exclude all warning messages and errors summary_ console_add_neg_select WARNING,summary"
        arg_file: "Read arguments from this file. File should be a valid XML file, and should contain elements of the form <Parameter name='PARAMETER_NAME' analysis='NODE_NAME' currentValue='VALUE' />."
        check_param: "Stop the program after the command parameters have been checked."
        max_threads: "Maximum thread count (0 unlimited threads); Default number of CPUs detected"
        delete_temp_files: "Delete the temporary files after the run completes."
        out_dir: "The output directory for result files."
        temp_dir: "The output directory for temporary files."
        analysis_files_path: "Default directory to search for analysis library files"
        batch_folder: "Full path to Agatha batch folder. All genotyping data will be streamed into this folder as'all_genotypes_by_snps.CHP.bin' and 'all_genotypes_by_snps.CHP.index.txt’."
        batch_folder_data_dir: "Name of directory inside batch_folder where the analysis suite data is written."
        force: "Force the files to process regardless of array type."
        chip_type: "Text identifier for chip."
        analysis_name: "Name to prepend to output files."
        report: "Print report.txt file of summary and genotyping statistics."
        report_file: "Optional full path of report.txt file."
        summaries_only: "Skip the genotyping step."
        x_probes_file: "The file that identifies the X chromosome probe ids."
        y_probes_file: "The file that identifies the Y chromosome probe ids."
        w_probes_file: "The file that identifies the W chromosome probe ids."
        z_probes_file:" The file that identifies the Z chromosome probe ids."
        sketch_target_output: "Write the quantile normalization distribution (or sketch) to a file for reuse with target_sketch option."
        sketch_target_output_file: "Optional fully_specified path of sketch.txt file."
        dual_channel_target_sketch: "Create sketches from separate channels (AT/GC)"
        sketch_target_input_file: "Name of the file containing sketch to use."
        sketch_target_scale_value: "Target to scale the sketch to"
        sketch_target_use_avg: "When there is a range of identical intensities, use the average of the corresponding target sketch values."
        dual_channel_normalization: "Use dual channel normalization."
        probabilities_output: "Output a file with comma_separated probabilities for BB,AB,AA,Ocean for each probeset and sample."
        summary_a5_output: "Print summary in a5 format instead of plain text."
        do_rare_het_adjustment: "Analyze probe performance for rare biallelic het calls.  Conditionally change to NoCall."
        rare_het_candidate_file: "File of probeset_ids and CEL name pairs that indicate candidates for rare het analysis"
        process_multi_alleles: "Augment genotyping workflow to accomodate multi_allelic snps (allele count > 2)"
        probeset_ids: "Tab delimited file with column 'probeset_id' specifying probesets to genotype."
        cdf_file: "The CDF input file."
        special_snps: "File specifying non_autosomal chromosome information."
        snp_specific_param_file: "File specifying SNP_specific paramaters overriding standard parameters in genotyping. File must have columns_ ProbeSetName, ShellBarrier, Ocean, Confidence, CSepPen and CSepThr.  File may also have optional final column_ Lambda."
        cel_files: "The file that identifies the cel files to process."
        gender_file: "File specifying genders for each CEL file. File must have columns cel_files and gender."
        inbred_file: "File specifying inbred het penalty for each CEL file. File must have columns cel_files and inbred_het_penalty."
        hints_file: "File specifying seed genotypes instead of DM algorithm"
        global_inbred_het_penalty: "Specifying global inbred het penalty value for each CEL file."
        igender_female_threshold: "The female threshold to use in the raw intensity gender call."
        igender_male_threshold: "The male threshold to use in the raw intensity gender call."
        artifact_reduction_clip: "Threshold for intensity log_ratio to be outlier"
        artifact_reduction_clip_pvcam: "Threshold for intensity log_ratio to be outlier scan image is from PVCam"
        artifact_reduction_open: "Minimum size of snow (isolated residuals) to remove"
        artifact_reduction_close: "Max gap to close between tentative artifacts"
        artifact_reduction_fringe: "Add a fringe to catch border features that might be poor."
        artifact_reduction_cc: "How many channels must support an artifact"
        artifact_reduction_trustcheck: "Completely untrusted, blemished probesets in samples are no_calls"
        artifact_reduction_output_trustcheck: "Output text file of blemished probesets with cel index"
        raw_gender_write_intensities_node_normalized_intensities_output_file: "Optional full path of normalized intensities output file.  I.e. Use this filename instead of IntensityScratchPadFileName_*."
        sketch_size: "The sketch size to use."
        normalization_write_intensities_node_normalized_intensities_output_file: "Optional full path of normalized intensities output file.  I.e. Use this filename instead of IntensityScratchPadFileName_*."
        blob_format_version: "Blob format version for storing genotyping result. 1.0=legacy, 2.0=multiallelic/copynumber."
        sample_multiplier: "Used for generating fake blob with large number of samples. Ex_ 10 samples x 500 multiplier 5000 fake samples."
        use_copynumber_call_codes: "Use copynumber aware call codes, instead of raw brlmmp call codes."
        allele_summaries: "Print file of intensities summarized by allele."
        allele_summaries_file: "Optional fully_specified path of allele_summaries.txt file."
        background_percentile: "The percentile obtained from the signals for a probeset."
        pedestal: "A given value by which to divide the background percentile."
        genotyping_node_snp_priors_input_file: "The string that identifies the snp priors to use when genotyping."
        genotyping_node_snp_posteriors_output: "Write snp posteriors to output when genotyping."
        genotyping_node_snp_posteriors_output_file: "Optional full path of snp_posteriors.txt file."
        genotyping_node_table_output: "Output matching matrices of tab delimited genotype calls and confidences."
        genotyping_node_a5_tables: "Output calls, confidences in hdf5 format."
        genotyping_node_calls_file: "Optional full path of calls.txt file."
        genotyping_node_confidences_file: "Optional full path of confidences.txt file."
        genotyping_node_probabilities_file: "Optional full path of probabilities template file.  The file is typically partitioned and integers inserted into the filename before the .txt suffix."
        genotyping_node_probabilities_file_sample_count: "Number of samples per probability file.  These files can be large, especially when running 1000's of samples."
        genotyping_node_copynumber_probeset_calls_file: "Optional full path of probeset copynumber calls file."
        genotyping_node_copynumber_override_special_snps: "Replace specialSnp copynumber gender designation with copynumber call"
        genotyping_node_brlmmp_HARD: "brlmmp hardshell"
        genotyping_node_brlmmp_SB: "brlmmp shellbarrier"
        genotyping_node_brlmmp_CM: "brlmmp callmethod (1=batch mode, 2=single sample mode)"
        genotyping_node_brlmmp_bins: "brlmmp bins"
        genotyping_node_brlmmp_mix: "brlmmp mix"
        genotyping_node_brlmmp_bic: "brlmmp bic"
        genotyping_node_brlmmp_CSepPen: "brlmmp CSepPen"
        genotyping_node_brlmmp_CSepThr: "brlmmp CSepThr"
        genotyping_node_brlmmp_lambda: "brlmmp lambda"
        genotyping_node_brlmmp_wobble: "brlmmp wobble"
        genotyping_node_brlmmp_copyqc: "brlmmp copyqc. 0 - no test for copy qc"
        genotyping_node_brlmmp_copytype: "brlmmp copytype. 0 - standard copy qc method"
        genotyping_node_brlmmp_MS: "brlmmp MS. confidence threshold"
        genotyping_node_brlmmp_ocean: "brlmmp ocean"
        genotyping_node_brlmmp_clustertype: "brlmmp clustertype. 1 standard 1_d clustering only"
        genotyping_node_brlmmp_IsoHetY: "brlmmp IsoHetY"
        genotyping_node_brlmmp_inflatePRA: "brlmmp inflatePRA. 0 no increase in uncertainty"
        genotyping_node_brlmmp_CP: "brlmmp contradiction penalty. 0 no penalty"
        genotyping_node_brlmmp_comvar: "boolean to indicate if common variance is used in all clusters."
        genotyping_node_brlmmp_K: "Scaling Parameter to use in transformations."
        genotyping_node_max_rare_het_count: "Max number of het calls for a probeset over all samples to trigger SCI analysis."
        genotyping_node_gc_channel_sci_threshold: "Max threshold for SCI values from intensities in the GC channel."
        genotyping_node_at_channel_sci_threshold: "Max threshold for SCI values from intensities in the AT channel."
        genotyping_node_major_hom_relative_min_percent: "Minimum percentage of calls that are hom in order to meet major hom criteria."
        genotyping_node_major_hom_absolute_min_thresh: "Minimum number of calls that are hom in order to meet major hom criteria."
        multi_allele_background_node_snp_priors_input_file: "The string that identifies the snp priors to use when genotyping."
        multi_allele_background_node_snp_posteriors_output: "Write snp posteriors to output when genotyping."
        multi_allele_background_node_snp_posteriors_output_file: "Optional full path of snp_posteriors.txt file."
        multi_allele_background_node_table_output: "Output matching matrices of tab delimited genotype calls and confidences."
        multi_allele_background_node_a5_tables: "Output calls, confidences in hdf5 format."
        multi_allele_background_node_calls_file: "Optional full path of calls.txt file."
        multi_allele_background_node_confidences_file: "Optional full path of confidences.txt file."
        multi_allele_background_node_copynumber_probeset_calls_file: "Optional full path of probeset copynumber calls file."
        multi_allele_background_node_copynumber_override_special_snps: "Replace specialSnp copynumber gender designation with copynumber call"
        multi_allele_background_node_brlmmp_HARD: "brlmmp hardshell"
        multi_allele_background_node_brlmmp_SB: "brlmmp shellbarrier"
        multi_allele_background_node_brlmmp_CM: "brlmmp callmethod (1=batch mode, 2=single sample mode)"
        multi_allele_background_node_brlmmp_bins: "brlmmp bins"
        multi_allele_background_node_brlmmp_mix: "brlmmp mix"
        multi_allele_background_node_brlmmp_bic: "brlmmp bic"
        multi_allele_background_node_brlmmp_CSepPen: "brlmmp CSepPen"
        multi_allele_background_node_brlmmp_CSepThr: "brlmmp CSepThr"
        multi_allele_background_node_brlmmp_lambda: "brlmmp lambda"
        multi_allele_background_node_brlmmp_wobble: "brlmmp wobble"
        multi_allele_background_node_brlmmp_copyqc: "brlmmp copyqc. 0 - no test for copy qc"
        multi_allele_background_node_brlmmp_copytype: "brlmmp copytype. 0 - standard copy qc method"
        multi_allele_background_node_brlmmp_MS: "brlmmp MS. confidence threshold"
        multi_allele_background_node_brlmmp_ocean: "brlmmp ocean"
        multi_allele_background_node_brlmmp_clustertype: "brlmmp clustertype. 1 - standard 1_d clustering only"
        multi_allele_background_node_brlmmp_transform: "brlmmp transform. (mva, rvt, ssf, ces, assf, ccs)"
        multi_allele_background_node_brlmmp_IsoHetY: "brlmmp IsoHetY"
        multi_allele_background_node_brlmmp_inflatePRA: "brlmmp inflatePRA. 0 - no increase in uncertainty"
        multi_allele_background_node_brlmmp_CP: "brlmmp contradiction penalty. 0 - no penalty"
        multi_allele_background_node_brlmmp_comvar: "boolean to indicate if common variance is used in all clusters."
        multi_allele_background_node_brlmmp_K: "Scaling Parameter to use in transformations."
        multi_allele_background_node_max_rare_het_count: "Max number of het calls for a probeset over all samples to trigger SCI analysis."
        multi_allele_background_node_gc_channel_sci_threshold: "Max threshold for SCI values from intensities in the GC channel."
        multi_allele_background_node_at_channel_sci_threshold: "Max threshold for SCI values from intensities in the AT channel."
        multi_allele_background_node_major_hom_relative_min_percent: "Minimum percentage of calls that are hom in order to meet major hom criteria."
        multi_allele_background_node_major_hom_absolute_min_thresh: "Minimum number of calls that are hom in order to meet major hom criteria."
        multi_allele_pairwise_node_snp_priors_input_file: "The string that identifies the snp priors to use when genotyping."
        multi_allele_pairwise_node_snp_posteriors_output: "Write snp posteriors to output when genotyping."
        multi_allele_pairwise_node_snp_posteriors_output_file: "Optional full path of snp_posteriors.txt file."
        multi_allele_pairwise_node_table_output: "Output matching matrices of tab delimited genotype calls and confidences."
        multi_allele_pairwise_node_a5_tables:  "Output calls, confidences in hdf5 format."
        multi_allele_pairwise_node_calls_file:  "Optional full path of calls.txt file."
        multi_allele_pairwise_node_confidences_file: "Optional full path of confidences.txt file."
        multi_allele_pairwise_node_copynumber_probeset_calls_file: "Optional full path of probeset copynumber calls file."
        multi_allele_pairwise_node_copynumber_override_special_snps: "Replace specialSnp copynumber gender designation with copynumber call"
        multi_allele_pairwise_node_brlmmp_HARD: "brlmmp hardshell"
        multi_allele_pairwise_node_brlmmp_SB: "brlmmp shellbarrier"
        multi_allele_pairwise_node_brlmmp_CM: "brlmmp callmethod (1=batch mode, 2=single sample mode)"
        multi_allele_pairwise_node_brlmmp_bins: "brlmmp bins"
        multi_allele_pairwise_node_brlmmp_mix: "brlmmp mix"
        multi_allele_pairwise_node_brlmmp_bic: "brlmmp bic"
        multi_allele_pairwise_node_brlmmp_CSepPen: "brlmmp CSepPen"
        multi_allele_pairwise_node_brlmmp_CSepThr: "brlmmp CSepThr"
        multi_allele_pairwise_node_brlmmp_lambda: "brlmmp lambda"
        multi_allele_pairwise_node_brlmmp_wobble: "brlmmp wobble"
        multi_allele_pairwise_node_brlmmp_copyqc: "brlmmp copyqc. 0 - no test for copy qc"
        multi_allele_pairwise_node_brlmmp_copytype: "brlmmp copytype. 0 - standard copy qc method"
        multi_allele_pairwise_node_brlmmp_MS: "brlmmp MS. confidence threshold"
        multi_allele_pairwise_node_brlmmp_ocean: "brlmmp ocean"
        multi_allele_pairwise_node_brlmmp_clustertype: "brlmmp clustertype. 1 - standard 1_d clustering only"
        multi_allele_pairwise_node_brlmmp_transform: "brlmmp transform. (mva, rvt, ssf, ces, assf, ccs)"
        multi_allele_pairwise_node_brlmmp_IsoHetY: "brlmmp IsoHetY"
        multi_allele_pairwise_node_brlmmp_inflatePRA: "brlmmp inflatePRA. 0 - no increase in uncertainty"
        multi_allele_pairwise_node_brlmmp_CP: "brlmmp contradiction penalty. 0 - no penalty"
        multi_allele_pairwise_node_brlmmp_comvar: "boolean to indicate if common variance is used in all clusters."
        multi_allele_pairwise_node_brlmmp_K: "Scaling Parameter to use in transformations."
        multi_allele_pairwise_node_max_rare_het_count:" Max number of het calls for a probeset over all samples to trigger SCI analysis."
        multi_allele_pairwise_node_gc_channel_sci_threshold: "Max threshold for SCI values from intensities in the GC channel."
        multi_allele_pairwise_node_at_channel_sci_threshold: "Max threshold for SCI values from intensities in the AT channel."
        multi_allele_pairwise_node_major_hom_relative_min_percent: "Minimum percentage of calls that are hom in order to meet major hom criteria."
        multi_allele_pairwise_node_major_hom_absolute_min_thresh: "Minimum number of calls that are hom in order to meet major hom criteria."
        multi_freq_flag: "Adjustment factor for the frequency of the cluster."
        multi_inflate_PRA: "Inflate amount of the posteriors covariance matrices"
        multi_ocean: "Analogous to the brlmmp ocean parameter but used in nulti_allele genotyping."
        multi_lambda_P: "Coefficient for pooling common variance."
        multi_wobble: ""
        multi_copy_distance_0to1: "Used to adjust empty clusters positions based on the nonempty cluster data"
        multi_copy_distance_1to2: "Used to adjust empty clusters positions based on the nonempty cluster data"
        multi_shell_barrier_0to1: "Push copy number 0 clusters away from copy number 1 clusters."
        multi_shell_barrier_1to2: "Push the copy number 2 cluster away from copy number 1 clusters."
        multi_confidence_threshold: "Assign NoCall if the genotyping confidence is larger than this number."
        multi_priors_input_file: "The string that identifies the multi_allelic priors to use when genotyping."
        multi_posteriors_output: "Write multi_allelic posteriors to output when genotyping."
        multi_posteriors_output_file: "Full path of multi_allelic posteriors file."
        cr_fail_threshold: "Theshold below which a CEL file fails Call Rate."
        cr_pass_threshold: "Theshold above which a CEL file passes Call Rate."
        docker_image: "Docker image to use"
    }

    command <<<
        set -uexo pipefail
        cmd_string=""
        if [ -z ~{cel_files_file} ]
        then
        echo "cel_files" > cel_files.txt
        echo '~{sep="\n" cel_files}' >> cel_files.txt
        else
        cp ~{cel_files_file} cel_files.txt
        fi
        cmd_string+=" --cel-files cel_files.txt"

        unzip ~{library_files_zip} -d ~{analysis_files_path}
        mv cel_files.txt ~{analysis_files_path}/

        cmd_string+=~{if program_version then " --version" else ""}
        cmd_string+=~{if user_help then " --user-help" else ""}
        cmd_string+=~{if defined(log_file) then " --log-file " + log_file else ""}
        cmd_string+=~{if defined(console_add_select) then " --console-add-select " + console_add_select else ""}
        cmd_string+=~{if defined(console_add_neg_select) then " --console-add-neg-select " + console_add_neg_select else ""}

        if [ -z ~{arg_file} ]
        then
        arg_file=$(find ~{analysis_files_path} -name *Step1*)
        else
        arg_file=~{analysis_files_path}/~{arg_file}
        fi
        cmd_string+=" --arg-file ${arg_file}"

        cmd_string+=~{if check_param then " --check-param" else ""}

        if [[ ~{max_threads} -gt 0 ]]
        then
        cmd_string+=" --max-threads ~{max_threads}"
        fi

        cmd_string+=~{if delete_temp_files then "" else " --delete-temp-files False"}
        cmd_string+=~{if defined(out_dir) then " --out-dir " + out_dir else ""}
        cmd_string+=~{if defined(temp_dir) then " --temp-dir " + temp_dir else ""}
        cmd_string+=" --analysis-files-path ~{analysis_files_path}"
        cmd_string+=" --batch-folder ~{batch_folder}"

        if [[ ~{batch_folder_data_dir} != AxiomAnalysisSuiteData ]]
        then
        cmd_string+=" --batch_folder_data_dir ~{batch_folder_data_dir}"
        fi

        cmd_string+=~{if force then "" else " --force False"}

        if [[ ~{chip_type} != apt2-genotype ]]
        then
        cmd_string+=" --chip-type ~{chip_type}"
        fi

        if [[  ~{analysis_name} != apt-genotype-step1 ]]
        then
        cmd_string+=" --analysis-name ~{analysis_name}"
        fi

        cmd_string+=~{if report then "" else " --report false --report_file " + report_file}
        cmd_string+=~{if summaries_only then " --summaries-only True" else ""}

        cmd_string+=~{if defined(x_probes_file) then " --x-probes-file " + x_probes_file else ""}
        cmd_string+=~{if defined(y_probes_file) then " --y-probes-file " + y_probes_file else ""}
        cmd_string+=~{if defined(w_probes_file) then " --w-probes-file " + w_probes_file else ""}
        cmd_string+=~{if defined(z_probes_file) then " --z-probes-file " + z_probes_file else ""}
        cmd_string+=~{if sketch_target_output then " --sketch-target-output true --sketch-target-output-file " + sketch_target_output_file else ""}
        cmd_string+=~{if dual_channel_target_sketch then "" else " --dual-channel-target-sketch False"}
        cmd_string+=~{if defined(sketch_target_input_file) then " --sketch-target-input-file " + sketch_target_input_file else ""}

        if [[ ~{sketch_target_scale_value} != "0.0" ]]
        then
        cmd_string+=" --sketch-target-scale-value ~{sketch_target_scale_value}"
        fi

        cmd_string+=~{if sketch_target_use_avg then "" else " --sketch-target-use-avg False"}
        cmd_string+=~{if dual_channel_normalization then "" else " --dual-channel-normalization False"}
        cmd_string+=~{if probabilities_output then " --probabilities-ouput True" else ""}
        cmd_string+=~{if summary_a5_output then " --summary-a5-output True" else ""}
        cmd_string+=~{if do_rare_het_adjustment then " --do-rare-het-adjustment True" else ""}
        cmd_string+=~{if defined(rare_het_candidate_file) then " --rare-het-candidate-file " + rare_het_candidate_file else ""}
        cmd_string+=~{if process_multi_alleles then " --process_multi_alleles True" else ""}
        cmd_string+=~{if defined(probeset_ids) then " --probeset-ids " + probeset_ids else ""}
        cmd_string+=~{if defined(cdf_file) then " --cdf-file " + cdf_file else ""}
        cmd_string+=~{if defined(special_snps) then " --special-snps " + special_snps else ""}
        cmd_string+=~{if defined(snp_specific_param_file) then " --snp-specific-param-file " + snp_specific_param_file else ""}
        cmd_string+=~{if defined(gender_file) then " -- gender-file " +  gender_file else ""}
        cmd_string+=~{if defined(inbred_file) then " --inbred-file " + inbred_file else ""}
        cmd_string+=~{if defined(hints_file) then " --hints-file " + hints_file else ""}

        if [[ ~{global_inbred_het_penalty} != "0.0" ]]
        then
        cmd_string+=" --global-inbred-het-penalty ~{global_inbred_het_penalty}"
        fi

        if [[ ~{igender_female_threshold} != "0.48" ]]
        then
        cmd_string+=" --igender-female-threshold ~{igender_female_threshold}"
        fi

        if [[ ~{igender_male_threshold} != "0.7" ]]
        then
        cmd_string+=" --igender-male-threshold ~{igender_male_threshold}"
        fi

        if [[ ~{artifact_reduction_clip} != "0.4" ]]
        then
        cmd_string+=" --artifact-reduction-clip ~{artifact_reduction_clip}"
        fi

        if [[ ~{artifact_reduction_clip_pvcam} != "0.43" ]]
        then
        cmd_string+=" --artifact-reduction-clip-pvcam ~{artifact_reduction_clip_pvcam}"
        fi

        if [[ ! ~{artifact_reduction_open} -eq 1 ]]
        then
        cmd_string+=" --artifact-reduction-open ~{artifact_reduction_open}"
        fi

        if [[ ! ~{artifact_reduction_close} -eq 3 ]]
        then
        cmd_string+=" --artifact-reduction-close ~{artifact_reduction_close}"
        fi

        if [[ ! ~{artifact_reduction_fringe} -eq 2 ]]
        then
        cmd_string+=" --artifact-reduction-fringe ~{artifact_reduction_fringe}"
        fi

        if [[ ! ~{artifact_reduction_cc} -eq 1 ]]
        then
        cmd_string+=" --artifact-reduction-cc ~{artifact_reduction_cc}"
        fi

        cmd_string+=~{if artifact_reduction_trustcheck then " --artifact-reduction-trustcheck True" else ""}
        cmd_string+=~{if artifact_reduction_output_trustcheck then " --artifact_reduction_output_trustcheck True" else ""}
        cmd_string+=~{if defined(raw_gender_write_intensities_node_normalized_intensities_output_file) then " --raw-gender-write-intensities-node-normalized-intensities-output-file " + raw_gender_write_intensities_node_normalized_intensities_output_file else ""}
        cmd_string+=~{if defined(sketch_size) then " --sketch_size " + raw_gender_write_intensities_node_normalized_intensities_output_file else ""}
        cmd_string+=~{if defined(normalization_write_intensities_node_normalized_intensities_output_file) then " --normalization-write-intensities-node-normalized-intensities-output-file " + normalization_write_intensities_node_normalized_intensities_output_file else ""}

        if [[ ~{blob_format_version} != "2.0" ]]
        then
        cmd_string+=" --blob-format-version ~{blob_format_version}"
        fi

        if [[ ! ~{sample_multiplier} -eq 1 ]]
        then
        cmd_string+=" --sample-multiplier ~{sample_multiplier}"
        fi

        cmd_string+=~{if use_copynumber_call_codes then " --use-copynumber-call-codes True" else ""}
        cmd_string+=~{if allele_summaries then " --allele-summaries True" else ""}
        cmd_string+=~{if defined(allele_summaries_file) then " --allele-summaries-file " + allele_summaries_file else ""}

        if [[ ~{background_percentile} != "0.1" ]]
        then
        cmd_string+=" --background-percentile ~{background_percentile}"
        fi

        if [[ ~{pedestal} != "256.0" ]]
        then
        cmd_string+=" --pedestal ~{pedestal}"
        fi

        cmd_string+=~{if defined(genotyping_node_snp_priors_input_file) then " --genotyping-node-snp-priors-input-file " + genotyping_node_snp_priors_input_file else ""}
        cmd_string+=~{if genotyping_node_snp_posteriors_output then " --genotyping-node-snp-posteriors-output True --genotyping-node-snp-posteriors-output-file" + genotyping_node_snp_posteriors_output_file else ""}
        cmd_string+=~{if genotyping_node_table_output then "" else " --genotyping-node_table-output False"}
        cmd_string+=~{if genotyping_node_a5_tables then " --genotyping-node-a5-tables True" else ""}
        cmd_string+=~{if defined(allele_summaries_file) then " --allele-summaries-file " + allele_summaries_file else ""}
        cmd_string+=~{if defined(genotyping_node_calls_file) then " --genotyping-node-calls-file " + genotyping_node_calls_file else ""}
        cmd_string+=~{if defined(genotyping_node_confidences_file) then " --genotyping-node-confidences-file " + genotyping_node_confidences_file else ""}
        cmd_string+=~{if defined(genotyping_node_probabilities_file) then " --genotyping-node-probablities-file " + genotyping_node_probabilities_file else ""}

        if [[ ! ~{genotyping_node_probabilities_file_sample_count} -eq 0 ]]
        then
        cmd_string+=" --genotyping-node-probabilities-file-sample-count ~{genotyping_node_probabilities_file_sample_count}"
        fi

        cmd_string+=~{if defined(genotyping_node_copynumber_probeset_calls_file) then " --genotyping-node-copynumber-probeset-calls-file " + genotyping_node_copynumber_probeset_calls_file else ""}
        cmd_string+=~{if genotyping_node_copynumber_override_special_snps then " --genotyping-node-copynumber-override-special-snps True" else ""}

        if [[ ! ~{genotyping_node_brlmmp_HARD} -eq 3 ]]
        then
        cmd_string+=" --genotyping-node-brlmmp_HARD ~{genotyping_node_brlmmp_HARD}"
        fi

        if [[ ~{genotyping_node_brlmmp_SB} != "0.45" ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-SB ~{genotyping_node_brlmmp_SB}"
        fi

        if [[ ! ~{genotyping_node_brlmmp_CM} -eq 1 ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-CM ~{genotyping_node_brlmmp_CM}"
        fi

        if [[ ! ~{genotyping_node_brlmmp_bins} -eq 100 ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-bins ~{genotyping_node_brlmmp_bins}"
        fi

        if [[ ! ~{genotyping_node_brlmmp_mix} -eq 1 ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-mix ~{genotyping_node_brlmmp_mix}"
        fi

        if [[ ~{genotyping_node_brlmmp_bic} != "2.0" ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-bic ~{genotyping_node_brlmmp_bic}"
        fi

        if [[ ~{genotyping_node_brlmmp_CSepPen} != "0.0" ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-CSepPen ~{genotyping_node_brlmmp_CSepPen}"
        fi

        if [[ ~{genotyping_node_brlmmp_CSepThr} != "16.0" ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-CSepThr ~{genotyping_node_brlmmp_CSepThr}"
        fi

        if [[ ~{genotyping_node_brlmmp_lambda} != "1.0" ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-lambda ~{genotyping_node_brlmmp_lambda}"
        fi

        if [[ ~{genotyping_node_brlmmp_wobble} != "0.05" ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-wobble ~{genotyping_node_brlmmp_wobble}"
        fi

        if [[ ~{genotyping_node_brlmmp_copyqc} != "0.0" ]]
        then
        cmd_string+=" --genotyping_node_brlmmp_copyqc ~{genotyping_node_brlmmp_copyqc}"
        fi

        if [[ ! ~{genotyping_node_brlmmp_copytype} -eq 0 ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-copytype ~{genotyping_node_brlmmp_copytype}"
        fi

        if [[ ~{genotyping_node_brlmmp_MS} != "0.05" ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-MS ~{genotyping_node_brlmmp_MS}"
        fi

        if [[ ~{genotyping_node_brlmmp_ocean} != "0.0" ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-ocean ~{genotyping_node_brlmmp_ocean}"
        fi

        if [[ ! ~{genotyping_node_brlmmp_clustertype} -eq 1 ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-clustertype ~{genotyping_node_brlmmp_clustertype}"
        fi

        if [[ ~{genotyping_node_brlmmp_IsoHetY} != "0.0" ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-IsoHetY ~{genotyping_node_brlmmp_IsoHetY}"
        fi

        if [[ ~{genotyping_node_brlmmp_inflatePRA} != "0.0" ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-inflatePRA ~{genotyping_node_brlmmp_inflatePRA}"
        fi

        if [[ ~{genotyping_node_brlmmp_CP} != "16.0" ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-CP ~{genotyping_node_brlmmp_CP}"
        fi

        cmd_string+=~{if genotyping_node_brlmmp_comvar then "" else " --genotyping-node-brlmmp-comvar False"}

        if [[ ~{genotyping_node_brlmmp_K} != "1.0" ]]
        then
        cmd_string+=" --genotyping-node-brlmmp-K ~{genotyping_node_brlmmp_K}"
        fi

        if [[ ! ~{genotyping_node_max_rare_het_count} -eq 3 ]]
        then
        cmd_string+=" --genotyping-node-max-rare-het-count ~{genotyping_node_max_rare_het_count}"
        fi

        if [[ ~{genotyping_node_gc_channel_sci_threshold} != "0.39" ]]
        then
        cmd_string+=" --genotyping-node-gc-channel-sci-threshold ~{genotyping_node_gc_channel_sci_threshold}"
        fi

        if [[ ~{genotyping_node_at_channel_sci_threshold} != "0.39" ]]
        then
        cmd_string+=" --genotyping-node-at-channel-sci-threshold ~{genotyping_node_at_channel_sci_threshold}"
        fi

        if [[ ~{genotyping_node_major_hom_relative_min_percent} != "80.0" ]]
        then
        cmd_string+=" --genotyping-node-major-hom-relative-min-percent ~{genotyping_node_major_hom_relative_min_percent}"
        fi

        if [[ ! ~{genotyping_node_major_hom_absolute_min_thresh} -eq 15 ]]
        then
        cmd_string+=" --genotyping-node-major-hom-absolute-min-thresh ~{genotyping_node_major_hom_absolute_min_thresh}"
        fi

        cmd_string+=~{if defined(multi_allele_background_node_snp_priors_input_file) then " --multi-allele-background-node-snp-priors-input-file " + multi_allele_background_node_snp_priors_input_file else ""}
        cmd_string+=~{if multi_allele_background_node_snp_posteriors_output then " --multi-allele-background-node-snp-posteriors-output True --multi-allele-background-node-snp-posteriors-output-file" + multi_allele_background_node_snp_posteriors_output_file else ""}
        cmd_string+=~{if multi_allele_background_node_table_output then "" else " --multi-allele-background-node-table-output False"}
        cmd_string+=~{if multi_allele_background_node_a5_tables then " --multi_allele_background_node_a5_tables True" else ""}
        cmd_string+=~{if defined(multi_allele_background_node_calls_file) then " --multi-allele-background-node-calls-file " + multi_allele_background_node_calls_file else ""}
        cmd_string+=~{if defined(multi_allele_background_node_confidences_file) then " --multi-allele-background-node-confidences-file " + multi_allele_background_node_confidences_file else ""}
        cmd_string+=~{if defined(multi_allele_background_node_copynumber_probeset_calls_file) then " --multi-allele-background-node-copynumber-probeset-calls-file " + multi_allele_background_node_copynumber_probeset_calls_file else ""}
        cmd_string+=~{if multi_allele_background_node_copynumber_override_special_snps then " --multi-allele-background-node-copynumber-override-special-snps True" else ""}

        if [[ ! ~{multi_allele_background_node_brlmmp_HARD} -eq 3 ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-HARD ~{multi_allele_background_node_brlmmp_HARD}"
        fi

        if [[ ~{multi_allele_background_node_brlmmp_SB} != "0.45" ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-SB ~{multi_allele_background_node_brlmmp_SB}"
        fi

        if [[ ! ~{multi_allele_background_node_brlmmp_CM} -eq 1 ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-CM ~{multi_allele_background_node_brlmmp_CM}"
        fi

        if [[ ! ~{multi_allele_background_node_brlmmp_bins} -eq 100 ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-bins ~{multi_allele_background_node_brlmmp_bins}"
        fi

        if [[ ! ~{multi_allele_background_node_brlmmp_mix} -eq 1 ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-mix ~{multi_allele_background_node_brlmmp_mix}"
        fi

        if [[ ~{multi_allele_background_node_brlmmp_bic} != "2.0" ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-bic ~{multi_allele_background_node_brlmmp_bic}"
        fi

        if [[ ~{multi_allele_background_node_brlmmp_CSepPen} != "0.0" ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-CSepPen ~{multi_allele_background_node_brlmmp_CSepPen}"
        fi

        if [[ ~{multi_allele_background_node_brlmmp_CSepThr} != "16.0" ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-CSepThr ~{multi_allele_background_node_brlmmp_CSepThr}"
        fi

        if [[ ~{multi_allele_background_node_brlmmp_lambda} != "1.0" ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-lambda ~{multi_allele_background_node_brlmmp_lambda}"
        fi

        if [[ ~{multi_allele_background_node_brlmmp_wobble} != "0.05" ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-wobble ~{multi_allele_background_node_brlmmp_wobble}"
        fi

        if [[ ~{multi_allele_background_node_brlmmp_copyqc} != "0.0" ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-copyqc ~{multi_allele_background_node_brlmmp_copyqc}"
        fi

        if [[ ! ~{multi_allele_background_node_brlmmp_copytype} -eq 0 ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-copytype ~{multi_allele_background_node_brlmmp_copytype}"
        fi

        if [[ ~{multi_allele_background_node_brlmmp_MS} != "0.05" ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-MS ~{multi_allele_background_node_brlmmp_MS}"
        fi

        if [[ ~{multi_allele_background_node_brlmmp_ocean} != "0.0" ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-ocean ~{multi_allele_background_node_brlmmp_ocean}"
        fi

        if [[ ! ~{multi_allele_background_node_brlmmp_clustertype} -eq 1 ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-clustertype ~{multi_allele_background_node_brlmmp_clustertype}"
        fi

        if [[ ~{multi_allele_background_node_brlmmp_transform} != mva ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-transform ~{multi_allele_background_node_brlmmp_transform}"
        fi

        if [[ ~{multi_allele_background_node_brlmmp_IsoHetY} != "0.0" ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-IsoHetY ~{multi_allele_background_node_brlmmp_IsoHetY}"
        fi

        if [[ ~{multi_allele_background_node_brlmmp_inflatePRA} != "0.0" ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-inflatePRA ~{multi_allele_background_node_brlmmp_inflatePRA}"
        fi

        if [[ ~{multi_allele_background_node_brlmmp_CP} != "16.0" ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-CP ~{multi_allele_background_node_brlmmp_CP}"
        fi

        cmd_string+=~{if multi_allele_background_node_brlmmp_comvar then "" else " --multi-allele-background-node-brlmmp-comvar False"}

        if [[ ~{multi_allele_background_node_brlmmp_K} != "1.0" ]]
        then
        cmd_string+=" --multi-allele-background-node-brlmmp-K ~{multi_allele_background_node_brlmmp_K}"
        fi

        if [[ ! ~{multi_allele_background_node_max_rare_het_count} -eq 3 ]]
        then
        cmd_string+=" --multi-allele-background-node-max-rare-het-count ~{multi_allele_background_node_max_rare_het_count}"
        fi

        if [[ ~{multi_allele_background_node_gc_channel_sci_threshold} != "0.39" ]]
        then
        cmd_string+=" --multi-allele-background-node-gc-channel-sci-threshold ~{multi_allele_background_node_gc_channel_sci_threshold}"
        fi

        if [[ ~{multi_allele_background_node_at_channel_sci_threshold} != "0.39" ]]
        then
        cmd_string+=" --multi-allele-background-node-at-channel-sci-threshold ~{multi_allele_background_node_at_channel_sci_threshold}"
        fi

        if [[ ~{multi_allele_background_node_major_hom_relative_min_percent} != "80.0" ]]
        then
        cmd_string+=" --multi-allele-background-node-major-hom-relative-min-percent ~{multi_allele_background_node_major_hom_relative_min_percent}"
        fi

        if [[ ! ~{multi_allele_background_node_major_hom_absolute_min_thresh} -eq 15 ]]
        then
        cmd_string+=" --multi-allele-background-node-major-hom-absolute-min-thresh ~{multi_allele_background_node_major_hom_absolute_min_thresh}"
        fi

        cmd_string+=~{if defined(multi_allele_pairwise_node_snp_priors_input_file) then " --multi-allele-pairwise-node-snp-priors-input-file " + multi_allele_pairwise_node_snp_priors_input_file else ""}
        cmd_string+=~{if multi_allele_pairwise_node_snp_posteriors_output then " --multi-allele-pairwise-node-snp-posteriors-output True --multi-allele-pairwise-node-snp-posteriors-output-file " + multi_allele_pairwise_node_snp_posteriors_output_file else ""}
        cmd_string+=~{if multi_allele_pairwise_node_table_output then "" else " --multi-allele-pairwise-node-snp-posteriors-output False"}
        cmd_string+=~{if multi_allele_pairwise_node_a5_tables then " --multi-allele-pairwise-node-a5-tables True" else ""}
        cmd_string+=~{if defined(multi_allele_pairwise_node_calls_file) then " --multi-allele-pairwise-node-calls-file " + multi_allele_pairwise_node_calls_file else ""}
        cmd_string+=~{if defined(multi_allele_pairwise_node_confidences_file) then " --multi-allele-pairwise-node-confidences-file " + multi_allele_pairwise_node_confidences_file else ""}
        cmd_string+=~{if defined(multi_allele_pairwise_node_copynumber_probeset_calls_file) then " --multi-allele-pairwise-node-copynumber-probeset-calls-file " + multi_allele_pairwise_node_copynumber_probeset_calls_file else ""}
        cmd_string+=~{if multi_allele_pairwise_node_copynumber_override_special_snps then " -multi-allele-pairwise-node-copynumber-override-special-snps True" else ""}

        if [[ ! ~{multi_allele_pairwise_node_brlmmp_HARD} -eq 3 ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-HARD ~{multi_allele_pairwise_node_brlmmp_HARD}"
        fi

        if [[ ~{multi_allele_pairwise_node_brlmmp_SB} != "0.45" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-SB ~{multi_allele_pairwise_node_brlmmp_SB}"
        fi

        if [[ ! ~{multi_allele_pairwise_node_brlmmp_CM} -eq 1 ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-CM ~{multi_allele_pairwise_node_brlmmp_CM}"
        fi

        if [[ ! ~{multi_allele_pairwise_node_brlmmp_bins} -eq 100 ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-bins ~{multi_allele_pairwise_node_brlmmp_bins}"
        fi

        if [[ ! ~{multi_allele_pairwise_node_brlmmp_mix} -eq 1 ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-mix ~{multi_allele_pairwise_node_brlmmp_mix}"
        fi

        if [[ ~{multi_allele_pairwise_node_brlmmp_bic} != "2.0" ]]
        then
        cmd_string+=" --mmulti-allele-pairwise-node-brlmmp-bic ~{multi_allele_pairwise_node_brlmmp_bic}"
        fi

        if [[ ~{multi_allele_pairwise_node_brlmmp_CSepPen} != "0.0" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-CSepPen ~{multi_allele_pairwise_node_brlmmp_CSepPen}"
        fi

        if [[ ~{multi_allele_pairwise_node_brlmmp_CSepThr} != "16.0" ]]
        then
        cmd_string+=" --mmulti-allele-pairwise-node-brlmmp-CSepThr ~{multi_allele_pairwise_node_brlmmp_CSepThr}"
        fi

        if [[ ~{multi_allele_pairwise_node_brlmmp_lambda} != "1.0" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-lambda ~{multi_allele_pairwise_node_brlmmp_lambda}"
        fi

        if [[ ~{multi_allele_pairwise_node_brlmmp_wobble} != "0.05" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-wobble ~{multi_allele_pairwise_node_brlmmp_wobble}"
        fi

        if [[ ~{multi_allele_pairwise_node_brlmmp_copyqc} != "0.0" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-copyqc ~{multi_allele_pairwise_node_brlmmp_copyqc}"
        fi

        if [[ ! ~{multi_allele_pairwise_node_brlmmp_copytype} -eq 0 ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-copytype ~{multi_allele_pairwise_node_brlmmp_copytype}"
        fi

        if [[ ~{multi_allele_pairwise_node_brlmmp_MS} != "0.05" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-MS ~{multi_allele_pairwise_node_brlmmp_MS}"
        fi

        if [[ ~{multi_allele_pairwise_node_brlmmp_ocean} != "0.0" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-ocean ~{multi_allele_pairwise_node_brlmmp_ocean}"
        fi

        if [[ ! ~{multi_allele_pairwise_node_brlmmp_clustertype} -eq 1 ]]
        then
        cmd_string+=" --multi_allele_pairwise_node_brlmmp_clustertype ~{multi_allele_pairwise_node_brlmmp_clustertype}"
        fi

        if [[ ~{multi_allele_pairwise_node_brlmmp_transform} != mva ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-transform ~{multi_allele_pairwise_node_brlmmp_transform}"
        fi

        if [[ ~{multi_allele_pairwise_node_brlmmp_IsoHetY} != "0.0" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-IsoHetY ~{multi_allele_pairwise_node_brlmmp_IsoHetY}"
        fi

        if [[ ~{multi_allele_pairwise_node_brlmmp_inflatePRA} != "0.0" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-inflatePRA ~{multi_allele_pairwise_node_brlmmp_inflatePRA}"
        fi

        if [[ ~{multi_allele_pairwise_node_brlmmp_CP} != "16.0" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-CP ~{multi_allele_pairwise_node_brlmmp_CP}"
        fi

        cmd_string+=~{if multi_allele_pairwise_node_brlmmp_comvar then "" else " --multi-allele-pairwise-node-brlmmp-comvar False"}

        if [[ ~{multi_allele_pairwise_node_brlmmp_K} != "1.0" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-brlmmp-K ~{multi_allele_pairwise_node_brlmmp_K}"
        fi

        if [[ ! ~{multi_allele_pairwise_node_max_rare_het_count} -eq 3 ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-max-rare-het-count ~{multi_allele_pairwise_node_max_rare_het_count}"
        fi

        if [[ ~{multi_allele_pairwise_node_gc_channel_sci_threshold} != "0.39" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-gc-channel-sci-threshold ~{multi_allele_pairwise_node_gc_channel_sci_threshold}"
        fi

        if [[ ~{multi_allele_pairwise_node_at_channel_sci_threshold} != "0.39" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-at-channel-sci-threshold ~{multi_allele_pairwise_node_at_channel_sci_threshold}"
        fi

        if [[ ~{multi_allele_pairwise_node_major_hom_relative_min_percent} != "80.0" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-major-hom-relative-min-percent ~{multi_allele_pairwise_node_major_hom_relative_min_percent}"
        fi

        if [[ ~{multi_allele_pairwise_node_major_hom_absolute_min_thresh} != "15.0" ]]
        then
        cmd_string+=" --multi-allele-pairwise-node-major-hom-absolute-min-thresh ~{multi_allele_pairwise_node_major_hom_absolute_min_thresh}"
        fi

        cmd_string+=~{if multi_freq_flag then " --multi-freq-flag True" else ""}

        if [[ ~{multi_inflate_PRA} != "0.0" ]]
        then
        cmd_string+=" --multi-inflate-PRA ~{multi_inflate_PRA}"
        fi

        if [[ ~{multi_ocean} != "1.0E-5" ]]
        then
        cmd_string+=" --multi-ocean ~{multi_ocean}"
        fi

        if [[ ~{multi_lambda_P} != "0.0" ]]
        then
        cmd_string+=" --multi-lambda-P ~{multi_lambda_P}"
        fi

        if [[ ~{multi_wobble} != "0.05" ]]
        then
        cmd_string+=" --multi_wobble ~{multi_wobble}"
        fi

        if [[ ~{multi_copy_distance_0to1} != "1.5" ]]
        then
        cmd_string+=" --multi-copy-distance-0to1 ~{multi_copy_distance_0to1}"
        fi

        if [[ ~{multi_copy_distance_1to2} != "0.2" ]]
        then
        cmd_string+=" --multi-copy-distance-1to2 ~{multi_copy_distance_1to2}"
        fi

        if [[ ~{multi_shell_barrier_0to1} != "0.05" ]]
        then
        cmd_string+=" --multi-shell-barrier-0to1 ~{multi_shell_barrier_0to1}"
        fi

        if [[ ~{multi_shell_barrier_1to2} != "0.05" ]]
        then
        cmd_string+=" --multi-shell-barrier-1to2 ~{multi_shell_barrier_1to2}"
        fi

        if [[ ~{multi_confidence_threshold} != "0.15" ]]
        then
        cmd_string+=" --multi-confidence-threshold ~{multi_confidence_threshold}"
        fi

        cmd_string+=~{if defined(multi_priors_input_file) then " --multi-priors-input-file " + multi_priors_input_file else ""}
        cmd_string+=~{if multi_posteriors_output then " --multi-posteriors-output True --multi-posteriors-output-file " + multi_posteriors_output_file else ""}

        echo $cmd_string
        apt-genotype-axiom $cmd_string
        grep -v ^# AxiomGT1.report.txt | awk '{print $1 "\t" $4}' > step1_simple.txt

        cat step1_simple.txt | awk '$2 >= ~{cr_pass_threshold} {print $1}' > passing_cel_files.txt
        cat step1_simple.txt | awk '$2 < ~{cr_fail_threshold} {print $1}' > failing_cel_files.txt
        cat step1_simple.txt | awk '($2 < ~{cr_pass_threshold} && $2 >= ~{cr_fail_threshold}){print $1}' > rescuable_cel_files.txt
        zip -r batch_folder.zip ~{batch_folder}/~{batch_folder_data_dir}/

        mkdir -p out/passing_cel_files
        mkdir -p out/failing_cel_files
        mkdir -p out/rescuable_cel_files

        for FILE in $(cat passing_cel_files.txt); do
            CEL=$(find /home/dnanexus/inputs -name $FILE)
            [[ -f $CEL ]] && mv $CEL out/passing_cel_files
        done

        for FILE in $(cat failing_cel_files.txt); do
            CEL=$(find /home/dnanexus/inputs -name $FILE)
            [[ -f $CEL ]] && mv $CEL out/failing_cel_files
        done

        for FILE in $(cat rescuable_cel_files.txt); do
            CEL=$(find /home/dnanexus/inputs -name $FILE)
            [[ -f $CEL ]] && mv $CEL out/rescuable_cel_files
        done
    >>>

    runtime {
        docker: docker_image
        cpu: "4"
        memory: "2 GB"
        disks: "local-disk 20 SSD"
    }

    output {
        File? genotype_report_file = "AxiomGT1.report.txt"
        File? genotype_calls_file = "AxiomGT1.calls.txt"
        File? genotype_posteriors_file = "AxiomGT1.snp-posteriors.txt"
        File? genotype_summary_file = "AxiomGT1.summary.txt"
        File? genotype_confidences_file = "AxiomGT1.confidences.txt"
        File passing_cel_files_file = "passing_cel_files.txt"
        File failing_cel_files_file = "failing_cel_files.txt"
        File rescuable_cel_files_file = "rescuable_cel_files.txt"
        Array[File] passing_cel_files = glob("out/passing_cel_files/*")
        Array[File] failing_cel_files = glob("out/failing_cel_files/*")
        Array[File] rescuable_cel_files = glob("out/rescuable_cel_files/*")
        File batch_folder_zip = "batch_folder.zip"
    }
}

task GatherGenotypes {
    input {
        Array[File] report_files
        Array[File] calls_files
        Array[File] posteriors_files
        Array[File] confidences_files
        String pid_file_name
    }

    meta {
        description: "Gather step for parrellelised genotyping"
    }

    command <<<
        report_files= (~{sep=' ' report_files})
        for (( i = 0; i < ${#report_files[@]}; i++ ))
        if $i=0
        then
        sed '/^#/ d'$report_files[$i] > AxiomGT1.report.txt
        else
        sed '/^#/ d'$report_files[$i] | sed -n '1!p' >> AxiomGT1.report.txt
        fi
        i=$i+1
        done
        #work out this grep to replace subsetted pid
        grep AxiomGT1.report.txt #%affymetrix-algorithm-param-apt-opt-probeset-ids=Axiom_PMRA.r3.step2.ps

        calls_files=(~{sep=' ' calls_files})
        for (( i = 0; i < ${#calls_files[@]}; i++ ))
        do
        if $i=0
        then
        cat $calls_files[$i] > AxiomGT1.calls.txt
        else
        sed '/^#/ d' $calls_files[$i] | sed -n '1!p' >> AxiomGT1.calls.txt
        fi
        done

        posteriors_files=(~{sep=' ' posteriors_files})
        for (( i = 0; i < ${#posteriors_files[@]}; i++ ))                                                                                                                                          i=0
        if $i=0
        then
        cat $posteriors_files[$i] >> AxiomGT1.snp-posteriors.txt
        else
        sed '/^#/ d'$posteriors_file[$i] | sed -n '1!p' >> AxiomGT1.snp-posteriors.txt
        fi
        i=$i+1
        done

        confidences_files=(~{sep=' ' confidences_files})
        for (( i = 0; i < ${#confidences_files[@]}; i++ ))
        if $i=0
        then
        cat $confidences_files[$i] >> AxiomGT1.confidences.txt
        else
        sed '/^#/ d'$confidences_file[$i] | sed -n '1!p' >> AxiomGT1.confidences.txt
        fi
        i=$i+1
        done
    >>>

    output {
        File report_file = "AxiomGT1.report.txt"
        File calls_file = "AxiomGT1.calls.txt"
        File posteriors_file = "AxiomGT1.snp-posteriors.txt"
        File summary_file = "AxiomGT1.summary.txt"
        File confidences_file = "AxiomGT1.confidences.txt"
    }
}

task ps_metrics {
    input {
        Boolean program_version = false
        Boolean user_help = false
        String? log_file
        String? console_add_select
        String? console_add_neg_select
        File? arg_file
        Boolean check_param = false
        File? posterior_file
        Boolean use_multi_allele = false
        File? multi_posterior_file
        File? call_file
        File? chp_files
        String batch_folder = "batch_folder"
        String batch_folder_data_dir = "AxiomAnalysisSuiteData"
        File pid_file = "OffTargetVariant.ps"
        File metrics_file = "metrics.txt"
        File batch_folder_posterior_file = "AxiomGT1.snp-posteriors.txt"
        File batch_folder_blob_file = batch_folder_data_dir + "/All_genotypes_by_snps.CHP"
        File batch_folder_multi_posterior_file = "AxiomGT1.snp-posteriors.multi.txt"
        String output_dir = "output"
        Boolean do_pHW = true
        Int precision = 4
        File? summary_file
        File? special_snps
        File? sample_list_file
        Float clustermin = 5.0
        Float y_restrict = 0.2
        Boolean use_supplemental = false
        Boolean use_ssp = false
        File? report_file
        File? multi_metrics_file
        File? genotype_freq_file
        Int min_genotype_freq_samples = 20
        Int ces_k = 2
        Boolean use_eureka = false

        String docker_image = "apt/2.11.0:latest"
    }

    meta {

    }

    parameter_meta {
        program_version: "Display the version info for this program."
        user_help: "Display help intended for end-users."
        log_file: "The name of the log file.  Defaults to 'PROGRAMNAME-NUMBER.log'."
        console_add_select: "Add selectors for console messages. e.g. to include all debug messages: --console-add-select debug to include all messages of level 3 or higher: --console-add-select '*:3'"
        console_add_neg_select: "Add selectors to be excluded from console messages. e.g. to exclude all warning messages and errors summary: --console-add-neg-select WARNING,summary"
        arg_file: {
                      description: "Read arguments from this file. File should be a valid XML file, and should contain elements of the form <Parameter name='PARAMETER-NAME analysis='NODE-NAME' currentValue='VALUE' />.",
                      extension: ".xml"
                  }
        check_param: "Stop the program after the command parameters have been checked."
        posterior_file: "Full path name of posterior file. File must exist and file is required."
        multi_posterior_file: "Full path name of multi-posterior file. File must exist and file is required with the parameter use-multi-allele."
        call_file: "Full path name of calls file. If the chp-files parameter is not used, file must exist and file is required."
        chp_files: "CHP files list file full path name. If the call-file parameter is not used, file must exist and file is required. File should contain paths to CHP files, one per line."
        batch_folder: "Path to batch folder. If the txt version is not used, parameter is required."
        batch_folder_data_dir: "Name of analysis data directory in batch folder."
        pid_file: "Full path name of pid file."
        metrics_file: "Name of the output biallelic metrics file."
        batch_folder_posterior_file: "Name of posterior file in batch-folder."
        batch_folder_blob_file: "Part of blob file name."
        batch_folder_multi_posterior_file: "Name of multi-posterior file in batch-folder."
        output_dir: "Path to output directory"
        do_pHW: "Calculate Hardy-Weinberg Probability and add new column to metrics file."
        precision: "The precision of the calculation results saved into metrics file."
        summary_file: "Full path name of summary file. Can accept input summary files in the txt and a5 (hdf5) format. If the batch folder option is not used with CN data, file must exist and file is required for CN0 mean calculation."
        special_snps: "Full path name of specialSnp file. With CN data, file must exist and is required for hemizygous calculations."
        sample_list_file: "Full path name of sample list file. Must exist."
        clustermin: "clustermin"
        y_restrict: "y-restrict"
        use_supplemental: "Calculate supplemental metrics and add them to metrics file. For supplemental metrics calculations, user must set summary file or batch-folder."
        use_ssp: "Calculate SSP metrics and add them to metrics file. For SSP metrics calculation, user must set summary file or batch folder, report file, and special-snps."
        report_file: "Full path name of report file. File is required for SSP metrics calculation."
        multi_metrics_file: "Name of the output multiallelic metrics file."
        genotype_freq_file: "Full path name of genotype frequency file. File is required for genotype frequency p-value calculation."
        min_genotype_freq_samples: "Minimal required number of samples to calculate genotype frequency p-values."
        ces_k: "CES transformation coefficient. Possible values are: 1, 2, 3, 4, 5."
        use_eureka: "Support eureka summary data."

    }

    command <<<
        set -uexo pipefail
        cmd_string=""
        cmd_string+=~{if program_version then " --version" else ""}
        cmd_string+=~{if user_help then " --user-help" else ""}
        cmd_string+=~{if defined(log_file) then " --log-file " + log_file else ""}
        cmd_string+=~{if defined(console_add_select) then " --console-add-select " + console_add_select else ""}
        cmd_string+=~{if defined(console_add_neg_select) then " --console-add-neg-select " + console_add_neg_select else ""}
        cmd_string+=~{if defined(arg_file) then " --arg-file " + arg_file else ""}
        cmd_string+=~{if check_param then " --check-param" else ""}
        cmd_string+=~{if defined(posterior_file) then " --posterior-file " + posterior_file else ""}
        cmd_string+=~{if defined(multi_posterior_file) then " --multi_posterior-file " + multi_posterior_file else ""}
        cmd_string+=~{if defined(call_file) then " --call_file " + call_file else ""}
        cmd_string+=~{if defined(chp_files) then " --chp_files " + chp_files else ""}

        if [[ ~{batch_folder}!=batch_folder ]]
        then
        cmd_string+=" --batch-folder ~{batch_folder}"
        fi

        if [[ ~{batch_folder_data_dir}!=AxiomAnalysisSuiteData ]]
        then
        cmd_string+=" --batch-folder-data-dir ~{batch_folder_data_dir}"
        fi









    >>>

    output {

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
        String docker_image = "apt/2.11.0:latest"

    }

    meta {
        description: "Ps_metrics and Ps_Classification"
    }

    parameter_meta {
        posterior_file: {
                            description: "AxiomGT1.snp-psoteriors.txt format file.",
                            extension: ".txt"
                        }
        calls_file: {
                        description: "AxiomGT1.calls.txt format file.",
                        extension: ".txt"
                    }
        report_file: {
                         description: "AxiomGT1.report.txt format file.",
                         extension: ".txt"
                     }
        summary_file: {
                          description: "AxiomGT1.summary.txt format file.",
                          extension: ".txt"
                      }
        library_files_zip: {
                               description: "Zip archive of Axiom Library Files in root.",
                               extension: ".zip"
                           }
        ps_list_file: {
                          description: "ProbeSet List format file.",
                          extension: ".txt, .ps"
                      }
        species_type : "Ps_classification mode: one of 'human', 'polyploid' or 'diploid'"
        docker_image: "Docker image to use"
    }

    command <<<
        set -uexo pipefail
        unzip ~{library_files_zip} -d library_files
        additional_args=""
        special_snps_file=$(find library_files -name *.specialSNPs)
        if [  ! -z $special_snps_file ]
        then
        additional_args="${additional_args} --special-snps $special_snps_file "
        fi
        if [ ! -z ~{ps_list_file} ]
        then
        additional_args="${additional_args} --pid-file ~{ps_list_file} "
        fi
        ps2snp_file=$(find library_files -name *.ps2snp_map.ps)
        ps-metrics --posterior-file ~{posterior_file} --call-file ~{calls_file} --report-file ~{report_file} --summary-file ~{summary_file} --metrics-file metrics.txt --output-dir . $additional_args
        ps-classification --species-type ~{species_type} --metrics-file metrics.txt --ps2snp-file $ps2snp_file --output-dir .

    >>>

    runtime {
        docker: docker_image
        cpu: "4"
        memory: "2 GB"
        disks: "local-disk 20 SSD"
    }

    output {
        File metrics_file = "metrics.txt"
        File performance_file = "Ps.performance.txt"
        File phr_ps_file = "PolyHighResolution.ps"
        File nmh_ps_file = "NoMinorHom.ps"
        File mhr_ps_file = "MonoHighResolution.ps"
        File crbt_ps_file = "CallRateBelowThreshold.ps"
        File otv_ps_file = "OffTargetVariant.ps"
        File other_ps_file = "Other.ps"
        File recommended_ps_file = "Recommended.ps"
    }
}

task FormatResultVCF {
    input {
        File calls_file
        File annotation_file
        String vcf_file = "output.vcf"
        File? snp_list_file
        File? sample_filter_file
        File? alternate_probeset_ids
        File? sample_attributes_file
        File? performance_file
        File? additional_snp_information_file
        Boolean export_alternate_sample_names = false
        String SNP_identifier_column = "ProbeSet_ID"
        Boolean export_confidence = false
        Boolean export_log_ratio  = false
        Boolean export_strength = false
        Boolean export_allele_signals = false
        Boolean export_chr_shortname = false
        Boolean export_single_samples = false
        String  call_format = "call_code"
        String? export_basecall_otv = "OTV"
        Boolean enable_divider = true
        String docker_image = "apt/2.11.0:latest"
    }

    meta {
        description: "Format Axiom genotyes into VCF"
    }

    parameter_meta {
        calls_file: {
                        description: "AxiomGT1.calls.txt format file.",
                        extension: ".txt"
                    }
        annotation_file: {
                             description: "Array type specific annotation database.",
                             extension: ".db"
                         }
        vcf_file: "Output file name."
        snp_list_file: {
                           description: "File containing list of selected SNP's for export.",
                           extension: ".txt, .ps"
                       }
        sample_filter_file: {
                                description: "List of sample names to filter for export. Generated by user or AxAS. Samples must exist in batch folder. Single column with header of 'cel_files' and sample names only, no paths.",
                                extension: ".txt"
                            }
        alternate_probeset_ids: {
                                    description: "File with alternate probeset ids.",
                                    extension: ".txt, .ps"
                                }
        sample_attributes_file: {
                                    description: "Sample attributes file in IGV format. Expected two header columns: [Sample Filename] and [Alternate Sample Name].",
                                    extension: ".txt"
                                }
        performance_file: {
                              description: "Performance file output from SNPolisher.",
                              extension: ".txt"
                          }
        additional_snp_information_file: {
                                             description: "TSV file with additional SNP information.",
                                             extension: ".txt"
                                         }
        export_alternate_sample_names: "Must be use in conjunction with sample_attributes_file that contains [Alternate Sample Name] column name."
        SNP_identifier_column: "Column name to be used as snp identifier for export. Must be one of annotation columns, e.g. {Affy_SNP_ID, dbSNP_RS_ID}."
        export_confidence: "Turn on/off exporting of confidence data"
        export_log_ratio: "Turn on/off exporting of log2 ratio (MvA) and contrast (CES)"
        export_strength: "Turn on/off exporting of strength (MvA) and size (CES)"
        export_allele_signals: "Turn on/off exporting of strength data"
        export_chr_shortname: "Use chromosome shortname in annotation sqlite db if available."
        export_single_samples: "One sample per file"
        call_format: "Sets format of export calls. Available formats: 'call_code' {AA/AB/BB} or 'base_call' {CC/CT/TT} or 'translated' {0/1/2/-1}."
        export_basecall_otv: "Use in conjunction with '--export-call-format base_call' to make a distinction between NoCall and OTV when exporting using AxiomGT1.calls.txt. Both will be replaced with '---' per DIR specification if this parameter is not supplied. (ex: OTV)"
        enable_divider: "Enable divider '/' between alleles"
        docker_image: "Docker image to use"
    }

    command <<<
        set -uexo pipefail
        arg_string="--calls-file ~{calls_file} --annotation-file ~{annotation_file}"
        arg_string="$arg_string ~{if(defined(snp_list_file)) then ("--snp-list-file " + snp_list_file) else ("")}"
        arg_string="$arg_string ~{if(defined(sample_filter_file)) then ("--sample-filter-file " + sample_filter_file) else ("")}"
        arg_string="$arg_string ~{if(defined(alternate_probeset_ids)) then ("--export-alternate-probeset-ids " + alternate_probeset_ids) else ("")}"
        arg_string="$arg_string ~{if(defined(sample_attributes_file)) then ("--sample-attributes-file " + sample_attributes_file) else ("")}"
        arg_string="$arg_string ~{if(defined(performance_file)) then ("--performance-file " + performance_file) else ("")}"
        arg_string="$arg_string ~{if(defined(additional_snp_information_file)) then ("--additional-snp-information-file " + additional_snp_information_file) else ("")}"
        arg_string="$arg_string ~{if(defined(export_basecall_otv)) then ("--export-basecall-otv " + export_basecall_otv) else ("")}"
        arg_string="$arg_string --export-alternate-sample-names ~{export_alternate_sample_names} "\
        "--snp-identifier-column ~{SNP_identifier_column} --export-confidence ~{export_confidence} "\
        "--export-log-ratio ~{export_log_ratio} --export-strength ~{export_strength} "\
        "--export-allele-signals ~{export_allele_signals} --export-chr-shortname ~{export_chr_shortname} "\
        "--export-single-samples ~{export_single_samples} --export-call-format ~{call_format} --enable-divider ~{enable_divider} "\
        "--export-vcf-file ~{vcf_file}"
        apt-format-result $arg_string
    >>>

    runtime {
        docker: docker_image
        cpu: "4"
        memory: "2 GB"
        disks: "local-disk 20 SSD"
    }

    output {
        File vcf_out_file = vcf_file
    }
}

task Package {
    input {
        Float blob_format_version = 2.000000
        Boolean create_multi_blob = true
        String species = "Human"
        File report_file
        File posteriors_file
        File calls_file
        File geno_qc_results_file
        File performance_file
        Int samples_per_chunk = 200
        String workflow_type = "probeset_genotyping"
        String? analysis_category
        File? multi_snp_posteriors_file
        String batch_name
        String docker_image = "apt/2.11.0:latest"
    }

    meta {
        description: "Format APT output into an Axiom Analysis Suite proejct folder"
    }

    parameter_meta {
        blob_format_version: "Blob format version for storing genotyping result."
        create_multi_blob: "Use this option to create multiallele genotyping blob using format version 2.0."
        species : "Ps_classification mode: one of 'Human', 'Polyploid' or 'Diploid'"

        report_file: {
                         description: "AxiomGT1.report.txt format file.",
                         extension: ".txt"
                     }
        posteriors_file: {
                             description: "AxiomGT1.snp-posteriors.txt format file.",
                             extension: ".txt"
                         }
        calls_file: {
                        description: "AxiomGT1.calls.txt format file.",
                        extension: ".txt"
                    }
        geno_qc_results_file: {
                                  description: "Result file of apt-geno-qc.",
                                  extension: ".txt"
                              }
        performance_file: {
                              description: "Performance file output from SNPolisher.",
                              extension: ".txt"
                          }
        samples_per_chunk: "Number of samples to be processed per chunk due to memory limitation."
        workflow_type: "Choose analysis workflow type for AxAS package: 'probeset_genotyping', 'automated_qc' or 'summary_only'."
        analysis_category: "Choose analysis category for multiallele AxAS package. 'cn_gt' for PharmacoScan, 'cn_gt_2' for CarrierScan."
        multi_snp_posteriors_file: "Full path to AxiomGT1.snp-posteriors.multi.txt"
        batch_name: "Name of zipped project folder"
        docker_image: "Docker image to use"

    }

    command <<<
        set -uexo pipefail
        mkdir data
        arg_string="--blob-format-version ~{blob_format_version} --create-multi-blob ~{create_multi_blob} "\
        "--species ~{species} --report-txt-file ~{report_file} --snp-posteriors-file ~{posteriors_file} "\
        "--geno-qc-res-file ~{geno_qc_results_file} --performance-file ~{performance_file} "\
        "--samples-per-chunk ~{samples_per_chunk} --batch-folder ~{batch_name} --genotype-data-dir data"
        arg_string="$arg_string ~{if(defined(analysis_category)) then ("--analysis-category " + analysis_category) else ("")}"
        arg_string="$arg_string ~{if(defined(multi_snp_posteriors_file)) then ("--multi-snp-posteriors-file " + multi_snp_posteriors_file) else ("")}"
        apt-package-util $arg_string
        zip -r ~{batch_name}.zip ~{batch_name}
    >>>

    runtime {
        docker: docker_image
        cpu: "4"
        memory: "2 GB"
        disks: "local-disk 20 SSD"
    }

    output {
        File axas_project_zip_file = batch_name + ".zip"
    }
}

task BatchReport {
    input {
        String batch_name
        File geno_qc_results_file
        File step1_report_file
        File genotyping_report_file
        File performance_file
        File script_file
        File template_file
        File css_file
        String docker_image = "dxaxiom/1.0.0:latest"
    }

    meta {
        description: "Generate a PDF report of Axiom Batch, Plate and Sample QC."
    }

    parameter_meta {
        batch_name: "Name of"
        geno_qc_results_file: {
                                  description: "Result file of apt-geno-qc.",
                                  extension: ".txt"
                              }
        step1_report_file: {
                               description: "AxiomGT1.report.txt format file from Step1 genotyping.",
                               extension: ".txt"
                           }
        genotyping_report_file: {
                                    description: "AxiomGT1.report.txt format file from Step2 genotyping",
                                    extension: ".txt"
                                }
        performance_file: {
                              description: "Performance file output from SNPolisher.",
                              extension: ".txt"
                          }
        script_file: {
                         description: "Report generating script.",
                         extension: ".py"
                     }
        template_file: {
                           description: "HTML template file.",
                           extension: ".html"
                       }
        css_file: {
                      description: "CSS file used to style intermediate HTML and the PDF.",
                      extension: ".css"
                  }
        docker_image: "Docker image to use."
    }

    String actual_batch_name = select_first([batch_name, '""'])
    command <<<
        set -uexo pipefail
        python3 ~{script_file} -n ~{actual_batch_name} -d ~{geno_qc_results_file} -q ~{step1_report_file} -g ~{genotyping_report_file} -p ~{performance_file} -t ~{template_file} -c ~{css_file}

    >>>

    runtime {
        docker: docker_image
        cpu: "2"
        memory: "2 GB"
        disks: "local-disk 20 SSD"
    }

    output {
        File batch_report_file = batch_name + '_report.pdf'
    }

}


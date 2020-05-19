import jinja2
import sys, getopt
import pandas as pd
import pdfkit
import matplotlib.pyplot as plt
import os

def main(argv):
    batch_name = ''
    dqc_report = ''
    step1_report_file = ''
    genotyping_report_file = ''
    performance_file = ''
    template_file = ''
    css_file = ''

    try:
        opts, args = getopt.getopt(argv,"hn:d:q:g:p:t:c:",["batch_name="])
    except getopt.GetoptError:
        print('test.py -n <batch_name> -d <dqc_report_file> -q <step1_report_file> -g <genotyping_report_file> -p <performance_file> -t <template_file> -c <css_file>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print(
                'test.py -n <batch_name> -d <dqc_report_file> -q <step1_report_file> -g <genotyping_report_file> -p <performance_file> -t <template_file> -c <css_file>')
            sys.exit()
        elif opt in ("-n", "--batch-name"):
            batch_name = arg
        elif opt in ("-d", "--dqc-report-file"):
            dqc_report = arg
        elif opt in ("-q", "--step1-report-file"):
            step1_report_file = arg
        elif opt in ("-g", "--genotyping-report-file"):
            genotyping_report_file = arg
        elif opt in ("-p", "--performance-file"):
            performance_file = arg
        elif opt in ("-t", "--template-file"):
            template_file = arg
        elif opt in ("-c", "--css-file"):
            css_file = arg

    #Batch Summary Table
    print(dqc_report)
    dqc_report_df = pd.read_csv(dqc_report, sep="\t", comment='#', header=0)
    dqc_report_df.set_index('cel_files', inplace=True)
    for column_name in dqc_report_df.columns.values.tolist():
        dqc_report_df.rename(columns={column_name: f'dqc_{column_name}'}, inplace=True)

    number_of_samples = len(dqc_report_df.index)

    step1_report_df = pd.read_csv(step1_report_file, sep="\t", comment='#', header=0)
    step1_report_df.set_index('cel_files', inplace=True)
    for column_name in step1_report_df.columns.values.tolist():
        step1_report_df.rename(columns={column_name: f'qc_{column_name}'}, inplace=True)
    number_of_plates = len(step1_report_df['qc_affymetrix-plate-barcode'].unique())
    number_dqc_passing = len(step1_report_df.index)

    genotyping_report_df = pd.read_csv(genotyping_report_file, sep="\t", comment='#', header=0)
    genotyping_report_df.set_index('cel_files', inplace=True)
    number_dqc_qccr_passing = len(genotyping_report_df.index)
    mean_qccr_passing = genotyping_report_df['call_rate'].mean().round(2)

    #Marker Metrics table
    performance_file_df = pd.read_csv(performance_file, sep="\t", comment='#', header=0)
    number_probesets = len(performance_file_df.index)
    number_markers = len(performance_file_df.query('BestProbeset == 1').index)
    phr_count = len(performance_file_df.query('ConversionType == "PolyHighResolution" & BestProbeset == 1').index)
    phr_percentage =round((phr_count/number_markers) * 100, 2)
    nmh_count = len(performance_file_df.query('ConversionType == "NoMinorHom" & BestProbeset == 1').index)
    nmh_percentage = round((nmh_count/number_markers) * 100, 2)
    mhr_count = len(performance_file_df.query('ConversionType == "MonoHighResolution" & BestProbeset == 1').index)
    mhr_percentage = round((mhr_count/number_markers) * 100, 2)
    crbt_count = len(performance_file_df.query('ConversionType == "CallRateBelowThreshold" & BestProbeset == 1').index)
    crbt_percentage = round((crbt_count/number_markers) * 100, 2)
    otv_count = len(performance_file_df.query('ConversionType == "OTV" & BestProbeset == 1').index)
    otv_percentage = round((otv_count/number_markers) * 100, 2)
    other_count = len(performance_file_df.query('ConversionType == "Other" & BestProbeset == 1').index)
    other_percentage = round((other_count/number_markers) * 100, 2)
    number_best_and_recommended = len(performance_file_df.query('BestandRecommended == 1').index)


    #Plate Summary table not possible without jumping through hoops die to missing barcode info in apt-geno-qc and broken BioPython

    #Sample Table
    mega_df = pd.concat([dqc_report_df, step1_report_df, genotyping_report_df], axis=1, sort=False)
    #Sample Filename, Pass/Fail, Plate Barcode, Scan Date, Well Position, DQC, QC CR, Final Call Rate, Het Rate
    sample_table_df = mega_df.filter(items=['dqc_cel_files', 'qc_affymetrix-plate-barcode', 'qc_affymetrix-plate-peg-wellposition', 'dqc_axiom_dishqc_DQC', 'qc_call_rate', 'call_rate', 'het_rate' ])
    sample_table_df.insert(2, 'Sample Pass', mega_df['call_rate'].notnull())
    sample_table_df.rename(columns={'qc_affymetrix-plate-barcode' : 'Plate Barcode',
                                    'qc_affymetrix-plate-peg-wellposition' : 'Well Position', 'dqc_axiom_dishqc_DQC': 'DQC',
                                    'qc_call_rate': 'QC Call Rate', 'call_rate': 'Final Call Rate',
                                    'het_rate': 'Final Het Rate'}, inplace=True)
    # plot graphs
    #dqc_qccr = sns.scatterplot(x="DQC", y="QC Call Rate", data=sample_table_df, hue="QC Call Rate")
    #dqc_qccr.get_figure().savefig("dqc_qccr.png")
    #qccr_het_rate_df = sample_table_df[sample_table_df['QC Call Rate'].notna()]
    #qccr_het_rate = sns.scatterplot(x="QC Call Rate", y="Final Het Rate", data=sample_table_df, hue="QC Call Rate")
    #qccr_het_rate.get_figure().savefig("qccr_het_rate.png")
    #dqc_qccr = sns.scatterplot(x="DQC", y="QC Call Rate", data=sample_table_df, hue="QC Call Rate")
    #dqc_qccr.get_figure().savefig("dqc_qccr.png")
    dqc_qccr_fig, ax1 = plt.subplots()
    ax1.scatter(sample_table_df['DQC'], sample_table_df['QC Call Rate'], c=sample_table_df['QC Call Rate'])
    ax1.set_title(f"{batch_name}: DQC vs QC Call Rate")
    ax1.set_xlabel("DQC")
    ax1.set_ylabel("QC Call Rate")
    dqc_qccr_fig.savefig("dqc_qccr.png")

    qccr_hetrate_fig, ax2 = plt.subplots()
    ax2.scatter(sample_table_df['QC Call Rate'], sample_table_df['Final Het Rate'], c=sample_table_df['Final Het Rate'])
    ax2.set_title(f"{batch_name}: QC Call Rate vs Final Het Rate")
    ax2.set_xlabel("QC Call Rate")
    ax2.set_ylabel("Final Het Rate")
    qccr_hetrate_fig.savefig("qccr_hetrate.png")

    sample_table_df = sample_table_df.round({'DQC': 2, 'QC Call Rate' : 2, 'Final Call Rate' : 2, 'Final Het Rate': 2})



    #templateLoader = jinja2.FileSystemLoader(searchpath="./")
    #templateEnv = jinja2.Environment(loader=templateLoader)
    #TEMPLATE_FILE = os.path.basename(template_file)
    #template = templateEnv.get_template(TEMPLATE_FILE)
    with open(template_file) as templatefile:
        template = jinja2.Template(templatefile.read())
    outputText = template.render(css_file=css_file, batch_name=batch_name, number_of_samples=number_of_samples, number_of_plates=number_of_plates,
                                 number_dqc_passing=number_dqc_passing,
                                 number_dqc_qccr_passing=number_dqc_qccr_passing, mean_qccr_passing=mean_qccr_passing,
                                 phr_count=phr_count, phr_percentage=phr_percentage, nmh_count=nmh_count,
                                 nmh_percentage=nmh_percentage, mhr_count=mhr_count, mhr_percentage=mhr_percentage,
                                 crbt_count=crbt_count, crbt_percentage=crbt_percentage, otv_count=otv_count,
                                 otv_percentage=otv_percentage, other_count=other_count, other_percentage=other_percentage,
                                 number_markers=number_markers, number_best_and_recommended=number_best_and_recommended,
                                 number_probesets=number_probesets, sample_table_df=sample_table_df)




    html_file = open(f'{batch_name}_report.html', 'w')
    html_file.write(outputText)
    html_file.close()
    pdfkit.from_file(f'{batch_name}_report.html', f'{batch_name}_report.pdf')


if __name__ == "__main__":
   main(sys.argv[1:])
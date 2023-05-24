// TODO nf-core: If in doubt look at other nf-core/modules to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/modules/nf-core/
//               You can also ask for help via your pull request or on the #modules channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided using the "task.ext" directive, see here:
//               https://www.nextflow.io/docs/latest/process.html#ext
//               where "task.ext" is a string.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
// TODO nf-core: Software that can be piped together SHOULD be added to separate module files
//               unless there is a run-time, storage advantage in implementing in this way
//               e.g. it's ok to have a single module for bwa to output BAM instead of SAM:
//                 bwa mem | samtools view -B -T ref.fasta
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process METAMAPS_MAP {
    tag "$meta.id"
    //label 'process_single'
    label 'process_medium'

    container "/home/antonio/metatropics/singularity/recipes/images/metamaps.sif"
    //conda "bioconda::metamaps=0.1.98102e9"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/metamaps:0.1.98102e9--h176a8bc_0':
    //    'quay.io/biocontainers/metamaps:0.1.98102e9--h176a8bc_0' }"

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path("*_results"), emit: metaclass
    tuple val(meta), path("*_results.meta"), emit: otherclassmeta
    tuple val(meta), path("*_results.meta.unmappedReadsLengths"), emit: metalength
    tuple val(meta), path("*_results.parameters"), emit: metaparameters

    // TODO nf-core: List additional required output channels/values here
    //path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // TODO nf-core: Where possible, a command MUST be provided to obtain the version number of the software e.g. 1.10
    //               If the software is unable to output a version number on the command-line then it can be manually specified
    //               e.g. https://github.com/nf-core/modules/blob/master/modules/nf-core/homer/annotatepeaks/main.nf
    //               Each software used MUST provide the software name and version number in the YAML version file (versions.yml)
    // TODO nf-core: It MUST be possible to pass additional parameters to the tool as a command-line string via the "task.ext.args" directive
    // TODO nf-core: If the tool supports multi-threading then you MUST provide the appropriate parameter
    //               using the Nextflow "task" variable e.g. "--threads $task.cpus"
    // TODO nf-core: Please replace the example samtools command below with your module's command
    // TODO nf-core: Please indent the command appropriately (4 spaces!!) to help with readability ;)
    //gunzip -c $input > read_temp.fastq
    """
    metamaps mapDirectly --all $args -q $input -o ${prefix}_classification_results --maxmemory 12
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metamaps_maps: \$(echo \$(metamaps --help) | grep MetaMaps | perl -p -e 's/MetaMaps v //g' )
    END_VERSIONS
    """
    }

# VEP_Plugins_Self
Custom plugins for the Variant Effect Predictor (VEP).

## FlankingSequence
This VEP plugin annotates the flanking sequence of a variant with the format "GCCCATCTGTC[G/T]TCTCTCTGATC". Default upstream/downstream length: 10. 

```bash
./vep -i input.vcf -o output.vcf -fa hg38.fasta --plugin FlankingSequence,10
```

## AnnotateClinVar
This VEP plugin provides advanced ClinVar annotations, including clinical significance, review status, disease name, HGVS, and ClinVar star-rating based on CLNREVSTAT. 

```bash
vep -i input.vcf -o output.vcf --plugin AnnotateClinVar,clinvar_file=/path/to/clinvar.vcf.gz,fields=CLNSIG,CLNDN,CLNSTAR
```

For simpler annotations without star-rating, you can use VEP’s --custom mode:

```bash
vep -i input.vcf -o output.vcf --custom file=/path/to/clinvar.vcf.gz,short_name=ClinVar,format=vcf,type=exact,coords=0,fields=CLNSIG%CLNDN
```

## MissenseZscoreTranscript
The plugin adds a new annotation field to the VEP output:
  - `MissenseZscore`: Missense Z-score value for the corresponding transcript.

Download the missenseByTranscript file from UCSC and change it to bed format.
```bash
wget https://hgdownload.soe.ucsc.edu/gbdb/hg38/gnomAD/pLI/missenseByTranscript.v4.1.bb
wget https://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/bigBedToBed
chmod a+x bigBedToBed
bigBedToBed missenseByTranscript.v4.1.bb missenseByTranscript.hg38.v4.1.bed
```

Usage

- 0: Ignore transcript version number (default)
- 1: Include transcript version number for exact matching

```bash
vep -i input.vcf -o output.vcf --plugin MissenseZscoreTranscript,/path/to/missenseByTranscript.hg38.v4.1.bed,1
```



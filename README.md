# VEP_Plugins_Self
Custom plugins for the Variant Effect Predictor (VEP).

## FlankingSequence
This VEP plugin annotates the flanking sequence of a variant with the format "GCCCATCTGTC[G/T]TCTCTCTGATC". Default upstream/downstream length: 10. 

```bash
./vep -i input.vcf -o output.vcf -fa hg38.fasta --plugin FlankingSequence,10
```

##step_1, build stringMLST database
stringMLST.py --buildDB -c /group/pathogens/plant_pathology/personal/Tongda/MSPD/Pragya/ring_test/pubMLST_Xylella/config.txt -k 35 -P NM
##step_2, stringMLST
less -S ./sample.list | while read i; do echo $i; cd $i; stringMLST.py --predict -1 /group/pathogens/plant_pathology/personal/Tongda/MSPD/Pragya/ring_test/$i/fastq_*.fastq -s --prefix /group/pathogens/plant_pathology/personal/Tongda/MSPD/Pragya/ring_test/pubMLST_Xylella/NM -o ./$i\_stringMLST.txt; cd ..;done
##step_3, makeblastdb
cd pubMLST_Xylella
less -S ../allele.list | while read i; do echo $i; makeblastdb -in /group/pathogens/plant_pathology/personal/Tongda/MSPD/Pragya/ring_test/pubMLST_Xylella/$i.fa -dbtype nucl -title $i -out $i\_blast_db;done
cd ..
##step_4, blast
less -S ./sample.list | while read i; do echo $i; cd $i; cat ../allele.list | while read a; do echo $a; blastn -db /group/pathogens/plant_pathology/personal/Tongda/MSPD/Pragya/ring_test/pubMLST_Xylella/$a\_blast_db -num_threads 8 -task megablast -outfmt 6 -max_hsps 1 -max_target_seqs 1 -query /group/pathogens/plant_pathology/personal/Tongda/MSPD/Pragya/ring_test/$i/*.fasta | grep $a\_ | awk '{print $2}' | sort | uniq -c | sort -nk1 -r > $a\_blast.txt;done; cd ..;done
##step_5, subset reads
less -S ./sample.list | while read i; do echo $i; cd $i; cat ../allele.list | while read a; do echo $a; blastn -db /group/pathogens/plant_pathology/personal/Tongda/MSPD/Pragya/ring_test/pubMLST_Xylella/$a\_blast_db -num_threads 8 -task megablast -outfmt 6 -max_hsps 1 -max_target_seqs 1 -query /group/pathogens/plant_pathology/personal/Tongda/MSPD/Pragya/ring_test/$i/*.fasta | grep $a\_ | awk '{print $1}' | sort -u > $a\_blast_reads_ID.txt;done; cd ..;done
less -S ./sample.list | while read i; do echo $i; cd $i; cat ../allele.list | while read a; do echo $a; /group/pathogens/Bioinfo_Software/KMCP/seqkit grep ./fastq_*.fastq -f $a\_blast_reads_ID.txt -o $a\_blast_reads.fastq;done; cd ..;done
##step_6, NGSpeciesID
less -S ./sample.list | while read i; do echo $i; cd $i; cat ../allele.list | while read a; do echo $a; NGSpeciesID --fastq ./$a\_blast_reads.fastq --ont --consensus --racon --outfolder ./$a\_NGSpeciesID;done; cd ..;done
##step_7, mlst
less -S ./sample.list | while read i; do echo $i; cd $i; cat ./*_NGSpeciesID/consensus_reference_*.fasta > all_mlst_alleles.fasta; mlst all_mlst_alleles.fasta > ./$i\_MLST.txt; cd ..;done
##step_8, inspecting all results
less -S ./sample.list | while read i; do echo $i; cat ./$i/*_stringMLST.txt; head -n 1 ./$i/*_blast.txt; cat ./$i/$i\_MLST.txt;done

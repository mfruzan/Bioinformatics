#!/bin/bash

# Make sure a directory is given as the second parameter
if [[ -z $2 ]]
then
  echo "Second argument missing (please specify folder name)."
  exit 1
fi
mkdir -p "$2/temp_fasta"
mkdir -p "$2/maf"
mkdir -p "$2/filtered_maf"

if [[ -z $3 ]]
then
  echo "Third argument missing (please specify divergance level, between 5 and 40)."
  exit 1
fi

divergance=$(($3));

identity=$((100-divergance));
if (( $identity <= 0 ||  $identity > 100))
then
  identity=10;
fi


cores=4
if [[ ! -z $4 ]]
then
  cores=$(($4));
fi



declare -i id=1;
maflist="";
query="";
queryfile="";
lines=$(cat $1 | wc -l)
echo Number of lines in file $1 : $lines;
#lines=$((lines+1));
while read line
do
  read -a arr <<< $line
  #echo ${arr[0]}, ${arr[1]}, ${arr[2]};

  if [ $id == 1 ];
  then
    query=${arr[0]}
    queryfile=${arr[1]}
  else
    echo $queryfile;
    echo ${arr[1]};
    twin=${query}_${arr[0]}
    if [[ ${arr[2]} ]]
    then
       echo "BWT index specified.";
       GSAlign -i ${arr[2]} -q ${queryfile} -o $2/maf/${twin} -no_vcf -t ${cores} -idy ${identity} -sen  -slen 15 -alen 250 -ind 50 -fmt 1;
    else
       echo "no index file";
       GSAlign -r ${arr[1]} -q ${queryfile} -o $2/maf/${twin} -no_vcf -t ${cores} -idy ${identity} -sen  -slen 15 -alen 250 -ind 50 -fmt 1;
    fi

    newmaf=${twin}".maf"
    java -jar MFbio.jar --task maf2uniquequery --srcdir $2/maf/${newmaf} --destdir $2/temp_fasta/${twin}".fa" --file1 $2/filtered_maf/${newmaf} --p1 50;
    queryfile=$2/temp_fasta/${twin}".fa";
    maflist=${newmaf}","${maflist};
  fi
  id=$((id+1));
  #echo $id;
done <<<$(cat $1)

#echo $maflist;
java -jar -Xmx100g MFbio.jar --task maf2msa --srcdir $2/filtered_maf --p1 ${maflist} --destdir $2/concatinated_msa.fa --file1 $2/msa.maf --file2 $1;

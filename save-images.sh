#!/bin/bash

i=0
mkdir $PWD/saved-images
curl -L https://raw.githubusercontent.com/gobomb/myDoc/master/k8s-image | while read image
do
        docker pull $image
        tarname=$(echo $image|sed "s#/#_#g")
        docker save $image >$PWD/saved-images/$tarname.tar
        echo $i: $tarname.tar saved
        ((i++))
done

tar zcvf saved-images.tar.gz saved-images

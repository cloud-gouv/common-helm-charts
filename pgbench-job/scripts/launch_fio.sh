#!/bin/sh

FILEPATH=./fiotest
RUNTIME={{ .Values.fio.runtime }}
NUMJOBS={{ .Values.fio.numjobs }}


function fiotest()
{
        local MODE="$1"
        local BS="$2"

        fio --filename="$FILEPATH" --size=1G \
                --rw="$MODE" --direct=1 --bs="$BS" \
                --ioengine=libaio --runtime="$RUNTIME" \
                --numjobs="$NUMJOBS" --time_based --group_reporting --name=blou \
                --iodepth=16
}


for MODE in read write randread randwrite
do
        for BS in 1k 4k 8k 16k 32k 1M 32M
        do
                echo ""
                echo "================== $BS / $MODE ================="
                echo ""
                fiotest "$MODE" "$BS"
        done
done


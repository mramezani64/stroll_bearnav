#check arguments
case $# in
    1) echo "path prefix: '$1'" ;;
    *) echo "wrong number of argument! 1st: path to folder containing maps."  1>&2
        exit -1
        ;;
esac

mkdir "results"

f="$1/icra_2019_adamap/long"

if [ 1 == 1 ]
then
rosrun dynamic_reconfigure dynparam set /navigator "{'summaryMap': False, 'plasticMap': False,'histogramRating': False,'remapRotGain': 1.0}"&
rosparam set names_map  [$(echo -ne "M000,";for i in $(seq -w 1 87);do echo -ne C0$i,;done)]
rosparam set names_view [$(for i in $(seq -w 1 87);do echo -ne A0$i,;done)]
roslaunch stroll_bearnav remapTest.launch folder_map:=$f folder_view:=$f
cp ~/.ros/Results.txt results/Map_adaptive_strict.txt
fi

path=`pwd`
f="`pwd`/icra_2019_adamap"
cd $f
make
cd $path

echo "in `pwd`"

for i in $(ls results/Map_adaptive*.txt|sed s/.txt//);do  grep reports $i.txt|awk '($23<5000){a=$21-$23;b=(sqrt(a*a)+384)%768-384;print sqrt(b*b)}'| tee $i.err|sort -nr > $i.srt;done

for i in $(ls results/Map_adaptive*.txt|sed s/.txt//);do 
echo >$i.tmp
for j in $(ls results/Map_adaptive*.txt|sed s/.txt//);do 
paste $j.err $i.err          |./icra_2019_adamap/t-test $confidence >>$i.tmp
done
echo "Error $i: " $(grep -c higher $i.tmp) $(grep -c smaller $i.tmp);
done

gnuplot icra_2019_adamap/map.gnu >results/map.fig

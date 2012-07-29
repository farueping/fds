#!/bin/bash -f

# defaults

queue=
background=no
QSUB=qsub

while getopts 'q:' OPTION
do
case $OPTION in
  q)
   queue="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

# If queue is null then use "background" to submit jobs
# on the local computer.

if [ -z "$queue" ]; then
  queue=
  QSUB="$BACKGROUND -u 75 -d 10 "
  background=yes;
  if ! [ -e $BACKGROUND ];  then
    echo "The file $BACKGROUND does not exist. Run aborted"
    exit
  fi
fi
if [ "$queue" != "" ]; then
   queue="-q $queue"
fi

# setup parameters

scratchdir=$SVNROOT/Utilities/Scripts/tmp
dir=$1
infile=$2

fulldir=$BASEDIR/$dir
in=$infile.fds
outerr=$fulldir/$infile.err
outlog=$fulldir/$infile.log
stopfile=$infile.stop

scriptfile=$scratchdir/script.$$

# ensure that various files and directories exist

if ! [ -e $FDS ];  then
  echo "The file $FDS does not exist. Run aborted"
  exit
fi
if ! [ -d $fulldir ]; then
  echo "The directory $fulldir does not exist. Run aborted."
  exit
fi
if ! [ -e $fulldir/$in ]; then
  echo "The fds input file, $fulldir/$in, does not exist. Run aborted."
  exit
fi
if [ $STOPFDS ]; then
 echo "stopping case: $infile"
 touch $fulldir/$stopfile
 exit
fi
if [ -e $fulldir/$stopfile ]; then
 rm $fulldir/$stopfile
fi
if [ -e $outlog ]; then
 rm $outlog
fi

# create run script

cat << EOF > $scriptfile
#!/bin/bash -f
#\$ -S /bin/bash
#\$ -N VV_$infile -e $outerr -o $outlog
#PBS -N VV_$infile -e $outerr -o $outlog
cd $fulldir

echo Time: \`date\`
echo Running $infile on \`hostname\`
echo Directory: \`pwd\`

$FDS $in 
EOF

echo Running $in 
if [ "$background" != "yes" ]; then
  chmod +x $scriptfile
  $QSUB $queue $scriptfile
else
  cd $fulldir
  $QSUB $FDS $in
fi

rm $scriptfile

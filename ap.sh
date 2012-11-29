#!/usr/local/bin/bash 
# Finds script location
thePWD=`mdfind -name ap.sh`
scriptDir=`dirname $thePWD`

DIFS=$IFS
NEWIFS=$'\n' 
NEWIFS=`echo -en "\n"`

IFS=$NEWIFS

#clear

type="TV Show"
#Numbers
se_no=0
ep_no=0
num=1	
specialParse=0 
overRide=0
#not a series indicator
w=0
d=0
c=0
v=0
crf="22"
count=0
thefps=0
rate=1000
description=""
help=0
_ffmpeg07="/usr/local/bin/ffmpeg07"
#_ffmpeg07="/usr/local/bin/ffmpeg"


counter=$#
fileIndex=1

#example array for episode titles
_episodeTitles=()
_seriesTitles=()

#Artwork
_hasArtwork=""
_artAdded=""

function checkRequirments () {
	#statements
	# _mp4info=`find /usr/local/bin -name mp4info`
	# _bbc=`find /usr/local/bin -name bbc`
	# _SetCustomIcon=`find /usr/local/bin -name SetCustomIcon`
	# _MP4Tagger=`find /usr/local/bin -name MP4Tagger`
	# _mkv=`find -L /Users/cdavies -name check_length_of_video.rb`

	_mp4info='/usr/local/bin/mp4info '
	_bbc='/usr/local/bin/bbc '
	_SetCustomIcon='/usr/local/bin/SetCustomIcon '
	_MP4Tagger='/usr/local/bin/MP4Tagger'
	_mkv='/Users/cdavies/Documents/bash/ap/check_length_of_video.rb '
}



function showHelp () {
	#statements
	helpText[0]="The following bin applications are needed for ap.sh to run:"
	helpText[1]=_mp4info
	helpText[2]=_bbc
	helpText[3]=_MP4Tagger
	helpText[4]=_SetCustomIcon
	helpText[5]="_mp4info _bbc _MP4Tagger _SetCustomIcon"
	requiredApps=(_mp4info _bbc _MP4Tagger _SetCustomIcon)
	#echo ${helpText[*]}
	
	index=${#helpText[@]}
	printf "  \n"
	for (( i = 0; i < $index; i++ )); do
		#statements
		printf "  %s\n" "${helpText[i]}"
	done
	printf "  \n"

}

function parseName () {

	# #Check if series number and episode number to be set
	# if [ $specialParse -eq 0 ]; then
	# 	# optional search character using [] - so for series name the . before s00 is optional [\.]
	# 	# and it is also delimited using \
	# 	episode_name=`echo ${no_ext} | cut -d "." -f 3` 
	# 	series_name=`echo ${no_ext} | grep -Pio ".*(?=\.s[0-9]{1,3})"`
	# 	se_no=`echo ${no_ext} | grep -Pio "(?<=s)[0-9]{1,3}" | bc`
	# 	ep_no=`echo ${no_ext} | grep -Pio "(?<=e)[0-9]{1,3}" | bc`
	# 	if [ -z "$episode_name" ]; then episode_name="Episode $ep_no"; fi
	# 	#if [ ${#se_no} -gt 2 ]; then se_no=0; fi
	# 	#if [ ${#ep_no} -gt 2 ]; then ep_no=0; fi
	# fi
	# if [ $specialParse -eq 1 ]; then
	# 	episode_name=`echo ${theFile} | cut -d "." -f 2` 
	# 	series_name=`echo ${theFile} | cut -d "." -f 1` 
	# 	se_no=0
	# 	ep_no=0	
	# fi

	numberFields=`echo ${no_ext} | awk -F . '{ print NF }'`
	if [[ "$type" == "movie" ]]; then
		numberFields=1;
		#statements
	fi
	case $numberFields in
		"1"   )	episode_name=`echo ${theFile} | cut -d "." -f 1` 
				series_name=`echo ${theFile} | cut -d "." -f 1` 
				se_no=0
				ep_no=0
		;;		
		"2"   )	episode_name=`echo ${theFile} | cut -d "." -f 2` 
				series_name=`echo ${theFile} | cut -d "." -f 1` 
				se_no=0
				ep_no=0		
		;;				
		"3"   )	episode_name=`echo ${no_ext} | cut -d "." -f 3` 
				series_name=`echo ${no_ext} | grep -Pio ".*(?=\.s[0-9]{1,3})"`
				se_no=`echo ${no_ext} | grep -Pio "(?<=s)[0-9]{1,3}" | bc`
				ep_no=`echo ${no_ext} | grep -Pio "(?<=e)[0-9]{1,3}" | bc`
		;;				
		"4"   )	episode_name=`echo ${no_ext} | awk -F . '{ print $3": " $4; }'` 
				series_name=`echo ${no_ext} | awk -F . '{ print $1; }'` 
				se_no=`echo ${no_ext} | grep -Pio "(?<=s)[0-9]{1,3}" | bc`
				ep_no=`echo ${no_ext} | grep -Pio "(?<=e)[0-9]{1,3}" | bc`
		;;							
	esac
}

function readExistingTags () {
	#statements
	if [[ "$theExt" != "avi" ]]; then
		local _episodeData
		_a1=""  #episode name
		_a3=""	#series name
		_a2=""	#series number
		_a4=""	#episode number
	 	_ep=""
	 	_sh=""
	 	_epno=""
	 	_shno=""
		_gotArt=""
		# 	TV Episode #: 
		# 	TV Season: 5
		# 	TV Episode ID: Cold Blood
		# 	TV Show: Doctor Who
		#	episode_name
		#	series_name
		#	se_no
		#	ep_no
		# /usr/local/bin/MP4Tagger -i "$theFile" -t

		_episodeData=`eval $_MP4Tagger -i \"$theFile\" -t`

		_ep=`echo $_episodeData | grep -Pio "(?<=TV Episode ID: ).*?\s{2,4}"`
		_sh=`echo $_episodeData | grep -Pio "(?<=TV Show: ).*?\s{2,4}"`
		_epno=`echo $_episodeData | grep -Pio "(?<=TV Episode #: )\d{1,2}"`
		_shno=`echo $_episodeData | grep -Pio "(?<=TV Season: )\d{1,2}"`
 		_gotArt=`echo $_episodeData | grep "Artwork: File contains artwork"`

		if [[ ! -z $_gotArt ]]; then _gotArt=" ✔ "; fi
		#  	printf "Existing Tags\n%-20s %-20s %-5s %-5s\n" "$_shno" "$_epno" "$_sh" "$_ep"
	 	# if [[ $overRide == 1 ]]; then

	  	if [[ ! -z $_ep ]]; then episode_name="${_ep}"; _a1="*"; fi
	  	if [[ ! -z $_sh ]]; then series_name="${_sh}"; _a3="*"; fi

		#  	if [[ -z $_shno ]]; then se_no="$_shno"; _a3="†"; fi
		#  	if [[ -z $_epno ]]; then ep_no="$_epno"; _a4="†"; fi
	 	# fi
		return 1;
	else
		return 0;	
	fi
}

function checkLength () {
	theLength=0
	echo "Checking length..."
	theCommand="ruby ${_mkv} \"${theFile}\""
	theLength=`eval $theCommand`
	echo "length is $theLength"
	if [[ "$theLength" != "0" ]]; then
		return 1;
	else
		return 0;	
	fi
}

function checkIsMovie () {
	# _isMovie=`mdls "$theFile" | grep -Pio "public.movie"`
	# Check if extension is in list of film extensions
	
	if [[ "${theEXTS[*]}" == *"$theExt"* ]]; then
		return 1; # is a film
	else
		return 0; # not a film
	fi
	
}

function getTags () {
	command="/usr/local/bin/mp4tagger -i '$1' -t"
	data=`eval $command`
	
	theShow=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=TV\ show\:\s).*"`
	theEpisodeName=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=TV\ Episode\ ID\:\ ).*"`
	theEpisodeNo=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=TV\ Episode\ \#\:\ ).*"`
	theSeasonNo=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=TV\ Season\:\ ).*"`
	theDescription=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=Description\:\ ).*"`
	theGenre=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=Genre\:\ ).*"`
	theMedia=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=MediaKind\:\ ).*"`
}

function transferTags () {
	theShow=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=TV\ show\:\s).*"`
	theEpisodeName=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=TV\ Episode\ ID\:\ ).*"`
	theEpisodeNo=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=TV\ Episode\ \#\:\ ).*"`
	theSeasonNo=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=TV\ Season\:\ ).*"`
	theDescription=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=Description\:\ ).*"`
	theGenre=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=Genre\:\ ).*"`
	theMedia=`$_MP4Tagger -i "$1" -t | grep -Pio "(?<=MediaKind\:\ ).*"`
	
	theString="$_MP4Tagger -i \"$2\" "
	
	if [ -n "$theShow" ]; then theString="${theString} --tv_show=\"${theShow}\""; fi
	if [ -n "$theEpisodeName" ]; then theString="${theString} --tv_episode_id=\"${theEpisodeName}\""; fi
	if [ -n "$theGenre" ]; then theString="${theString} --genre=\"${theGenre}\""; fi
	if [ -n "$theSeasonNo" ]; then theString="${theString} --tv_season=\"${theSeasonNo}\""; fi
	if [ -n "$theEpisodeNo" ]; then theString="${theString} --tv_episode_n=\"${theEpisodeNo}\""; fi
	if [ -n "$theDescription" ]; then theString="${theString} --description=\"${theDescription}\""; fi
	if [ -n "$theMedia" ]; then theString="${theString} --media_kind=\"${theMedia}\""; fi
	
	theString="${theString} -o"
	echo "Transferring tags ..."
	eval $theString
}


function find_db () {
    if [[ ! -a $dbPath ]]; then
		echo "Database missing"
		sql_query="create table $dbTable1 (filename TEXT, type TEXT);"	
		sqlite3 ~/Desktop/FinderFiles.db "$sql_query"
		
		#echo "$sql_query"
		sql_query="create table $dbTable2 (filename TEXT, type TEXT);"	
		
		sqlite3 ~/Desktop/FinderFiles.db "$sql_query"
		echo "Database created"
	fi


}

function write_data () {
    local dbTable="theResults"
    local dbPath="/Users/cdavies/.apsh/apsh.db"
	if [[ ! -a "$dbPath" ]]; then
		echo "Database missing"
		sql_query="CREATE TABLE theResults (episode_name TEXT, series_name TEXT, ep_no INTEGER, se_no INTEGER, width INTEGER, height INTEGER, length INTEGER, bitrate INTEGER, fps INTEGER);"
		sqlite3 "$dbPath" "$sql_query"
	fi
	# Find tag in the xml, convert tabs to spaces, remove leading spaces, remove the tag.
    sql_query="insert into $dbTable ('episode_name','series_name','ep_no','se_no','width','height','length','bitrate','fps') values (\"$episode_name\",\"$series_name\",\"$ep_no\",\"$se_no\",\"$width\",\"$height\",\"$theLength\",\"${bitrate}\",\"$fps\");"
	sqlite3 $dbPath "$sql_query"	
}

function progressBar () {
	local theFrame=0
	clear
	sleep 3	
	completed=0
	check="2"

	while [[ "$check" -gt "0" ]]; do

#	while [[ "$theFrame" -lt "$theLength" ]]; do
	  	sleep 4
		theLine=$(tail -n 2 /tmp/vstats | head -n 1 | cut -c 7-12 | bc)	
		#theFrame=$(echo $(tail -n 2 /tmp/vstats | head -n 1 | sed 's/frame=//g' | sed 's/ q=.*//g'))
		#theFrame=$(tail -n 1 /tmp/vstats | cut -d = -f 2 | cut -d " " -f 2 | bc)
		#theFrame=$(($theFrame + 1))
		completed=$(echo "scale=2; $theLine / $theLength * 100" | bc)
		#check=`top -o cpu -l 2 | grep ffmpeg | cut -c 8-13 | tail -n 1`
		check=`top -l 1 -stats pid,command | grep -c ffmpeg`
		#echo "$check"                              
		# if [[ $check == "ffmpeg" ]]; then
		# 		#statements
		# 		echo "is equal"
		# 	fi
		#echo $theFrame $theLength
		printf "Completed %2.0f%s\tFrame %s / %s\r" $completed "%" $theLine $theLength
	done	
	rm /tmp/vstats
	return 99
}
function float_eval()
{
    local float_scale=2
	local stat=0
    local result=0.0
    if [[ $# -gt 0 ]]; then
        result=$(echo "scale=$float_scale; $*" | bc -q 2>/dev/null)
        stat=$?
        if [[ $stat -eq 0  &&  -z "$result" ]]; then stat=1; fi
    fi
    echo "$result"
    return $stat
}
function convertFile () {
		# trap "killall ffmpeg $SCRIPT; exit" INT TERM EXIT
		# Kill & clean if stopped.
		#echo "xxxxx"
		#Check if width exceeds 960 x 540
		maxWidth=1280
		maxHeight=724
		maxFps=25		
		local current=0
		
		echo "$theLength frames to process..."
		if [ $(bc <<< "$fps >= $maxFps") -eq 1 ]; then fps="25.00"; fi
		aspect=$(echo "scale=3; $width/$height" | bc)
		
		if [ $((width)) -gt $((maxWidth)) ]; then
			width=$maxWidth
			height=$(echo "scale=0; $width/$aspect" | bc)
			widthCheck=`expr $width % 2`
			heightCheck=`expr $height % 2`
			#if resulting size is odd, add 1 to even it up			
			if [ $heightCheck = "1" ]; then let "height++";fi
			if [ $widthCheck = "1" ]; then let "width++";fi
			echo "size changed to $width x $height"
		fi
		
		# FFMPEG Command
		if [[ -e /tmp/vstats ]]; then rm /tmp/vstats; fi
		#Makes the named pipe
		# mkfifo ffmpegStatus
		
		# if [[ "$flatten" == "1" ]]; then
		# 			theCommand="$_ffmpeg07"
		# 			theCommand="(${theCommand} -y -vstats_file /tmp/vstats -i \"$theFile\" \
		# 			-acodec copy -vcodec copy -threads 0 \"$outfile\" 2> /dev/null) &"
		# 		fi
		# if [[ "$flatten" == "0" ]]; then
			theCommand="$_ffmpeg07"
			if [ -n "$time" ]; then theCommand="${theCommand} -t ${time}"; fi
			# theCommand="${theCommand} -vstats_file ./.cdtmpout.txt -loglevel quiet -y \
			# 	-i \"$theFile\" -acodec libfaac -ab 160k -ar 48000 -ac 2 \
			# 	-s \"$width\"x\"$height\" -aspect \"$aspect\" -vcodec libx264 -r $fps \
			# 	-vpre normal -crf $crf -threads 0 \"$outfile\" 2>./ffmpegStatus.txt"

			if [[ "$flatten" != "1" ]]; then 
				theCommand="${theCommand} -y -vstats_file /tmp/vstats -i \"$theFile\""
				theCommand="${theCommand} -acodec libfaac -ab 160k -ar 48000 -ac 2"
				theCommand="${theCommand} -s \"$width\"x\"$height\" -aspect \"$aspect\" "
				theCommand="${theCommand} -vcodec libx264 -r $fps -vpre normal"
				theCommand="${theCommand} -crf $crf -threads 0"
			fi
			if [[ "$flatten" == "1" ]]; then 
				theCommand="${theCommand} -y -i \"$theFile\" -acodec copy -vcodec copy"
			fi
			
			theCommand="(${theCommand} \"$outfile\" 2> /dev/null) &"
		# fi
		
		#-vpre normal -crf $crf -threads 0 \"$outfile\" 2>/dev/null &"		
		if [ -n "$flatten" ]; then echo "flatten is $flatten"; fi
		echo $theCommand
		eval $theCommand
		#exit 22
		#rm ffmpegStatus
	
}

function setCustomIcon () {
	local tier0=`ls *.* | grep "cover." | head -n 1`
	local tier1=`ls *.* | grep "\.j\|\.png" | head -n 1`
	local tier3=`ls *.* | grep "${no_ext}\.j\|${no_ext}\.png" | head -n 1`
#	local tier2=`ls *.* | grep "${series_name{.${episode_name}\.j\|${series_name{.${episode_name}\.png" | head -n 1`
	
	if [[ -f $tier0 ]]; then coverFile=$tier0; fi
	if [[ -f $tier1 ]]; then coverFile=$tier1; fi
	if [[ -f $tier2 ]]; then coverFile=$tier2; fi
	if [[ -f $tier3 ]]; then coverFile=$tier3; fi
		
	if [ -n "$coverFile" ]; then 
		_artAdded=" * "
		# #If we find the coverart file check for pre-existing embedded art and delete it.
		theCommand="/usr/local/bin/mp4art" 
		isArtwork=`mp4info "$theFile" | grep "Cover Art pieces: "`	
		if [ -n "$isArtwork" ]; then
			# If we find existing cover art, remove, otherwise skip to adding only
			echo "Remove old artwork."
			theCommand="${theCommand} --remove"
			eval $theCommand
		fi
		echo "Adding artwork from $coverFile"
		theCommand="${theCommand} --add \"${coverFile}\" --quiet \"$theFile\""
		eval $theCommand
		echo "Artwork addred"
		#Sets the custom finder icon
		theCommand="DeRez -only icns \"$coverFile\" > \"${theFile}.rsrc\""
		eval $theCommand
		theCommand="Rez -append \"${theFile}.rsrc\" -o \"${theFile}\""
		eval $theCommand
		#echo SetFile -a C "${theFile}"
		theCommand="SetFile -a C \"${theFile}\""
		eval $theCommand
		echo "Custom icon set"
		rm *.rsrc
	fi

}

function viewTags () {
#	echo $counter
#	echo $fileIndex
	# if [[ $fileIndex == 1 ]]; then
	# 	printf '%-4s %-4s | %6s | %4s | %5s | %-1s%-2s | %-1s%-3s | ART | %-1.1s%-20s %-1.1s%-s\n' \
	# 	"W" "H" "Frames" "Kbps" "fps" "" "se" "" "ep" "" "Series" "" "Episode"
	# fi 

	# printf '%-4dx%-4d | %6s | %4s | %5s | %-1s%-2d | %-1s%-3d | %3s | %-1.1s%-20.20s %-1.1s%-s\n' \
	# "$width" "$height" "$theLength" "${bitrate}" "$fps" \
	# "$_a2" "$se_no" "$_a42" "$ep_no" "$_artAdded" "$_a3" "$series_name" "$_a1" "$episode_name" 
	
	
	
	#VIEW TAGS
	if [[ $v == 1 ]]; then
		# theCommand="${_MP4Tagger} -i \"${theFile}\" -t"
		# eval $theCommand | grep -Pio ".*?: [A-za-z0-9].*"

		theCommand="ruby $scriptDir/printResults.rb '${theFile}'"
		eval $theCommand
	fi	
	let "fileIndex++"
}

function viewTags2 () {
	local _episodes
	# local fieldWidth=20.20

	printf '%-4dx%-4d | %6s | %4s | %5s | %-1s%-2d | %-1s%-3d | %3s | %-1.1s%-${fieldwidth}s %-1.1s%-s\n' \
	"$width" "$height" "$theLength" "${bitrate}" "$fps" \
	"$_a2" "$se_no" "$_a4" "$ep_no" "$_gotArt" "$_a3" "$series_name" "$_a1" "$episode_name"	
	
#	theResults=()
#	theResults[fileIndex]=( "$fileIndex" )
#	echo "$fileIndex--> ${theResults[fileIndex]}"
#	fileIndex=$((fileIndex+1))
#	echo "index $fileIndex number in array ${#theResults[@]}"
}

function printTags () {
	# newNames=("${newNames[@]}" "$newName") 
	local fieldWidth
	# echo $results[@]
	# echo $results | awk '{ print NR; print NF; }'
	# echo $results >> ~/Desktop/results.txt
	# echo ${_episodeTitles[@]}
	# echo ${_seriesTitles[@]}
	# echo ${#_seriesTitles[@]}
	# 
	# echo "count --> ${#_seriesTitles[*]}"
	
	# $1 is the line separator
	fieldWidth=`for (( i = 0; i < ${#results[@]}; i++ )); do echo "${results[i]}"; done | awk -F "|" 'BEGIN{x=0;}{
	length($12); $12; if (length($12)>x) {x=length($12)}}
	END{printf "%d", x}'`
	
	fieldWidth=`echo $fieldWidth | bc`
	# local fieldWidth=20.20
	
	 # echo "Field $fieldWidth"
	if [[ $fileIndex == 1 ]]; then
		printf '%-4s %-4s │ %6s │ %4s | %5s | %-1s%-2s | %-1s%-3s | ART | %-1.1s%-'$fieldwidth's %-1.1s%-s\n' \
		"W" "H" "Frames" "Kbps" "fps" "" "se" "" "ep" "" "Series" "" "Episode"
	fi 
	
	# clear
	echo "" | awk -v awkName="$fieldWidth" '{printf "\n\n%-4s x %-4s ┃ %6s ┃ %4s ┃ %5s ┃ %-2s ┃ %-3s ┃ ART ┃ %-*.*s ┃ %s\n%-s\n", "W", "H", "Frames", "Kbps", "fps", "se", "ep", awkName, awkName, "Series", "Episode", "━━━━━━━━━━━━╋━━━━━━━━╋━━━━━━╋━━━━━━━╋━━━━╋━━━━━╋━━━━━╋" }'
	
	for (( i = 0; i < ${#results[@]}; i++ )); do 
	#echo ${results[i]}
	echo ${results[i]} | awk -F "|" -v awkName="$fieldWidth" '
	{printf "%-4s x %-4s ┃ %6s ┃ %4s ┃ %5s ┃ %-2s ┃ %-3s ┃ %-3s ┃ %-*.*s ┃ %s\n", $1, $2, $3, $4, $5, $7, $9, $10, awkName, awkName, $12, $14 }'
	done
}
		
function read_db () {
    echo $@
    se_no=$1
    ep_no=$2
    series_name=$3
	dbPath="~/Documents/episodes.db"

    # Find tag in the xml, convert tabs to spaces, remove leading spaces, remove the tag.
    sql_query="select episode_name from episodes where ENO like '$ep_no' AND SNO like '$se_no' AND series like '$series_name';"
	episode_name=`sqlite3 ~/Documents/episodes.db "$sql_query"`
	#echo $episode_name
	#echo $dbPath
    sql_query="select description from episodes where ENO like '$ep_no' AND SNO like '$se_no' AND series like '$series_name';"
	description=`sqlite3 ~/Documents/episodes.db "$sql_query"`
	#echo $description
	echo "Renaming $episode_name"	
}

function write_db () {
    local se_no=$1
    local ep_no=$2
    local series_name=$3
    local episode_name=$4
    local dbTable="episodes"
	local dbPath="~/Documents/episodes.db"

    # Find tag in the xml, convert tabs to spaces, remove leading spaces, remove the tag.
    sql_query="insert into episodes ('episode_id','series','episode_name','description') values ('s${se_no}e${ep_no}','$series_name','$episode_name','');"
	
	#insert into episodes ("episode_id","series","episode_name","description") values ("s$se_noe$ep_no","$series_name","$episode_name","");
	
#	sqlite3 $dbPath "$sql_query"
	
	echo "$sql_query"
}

function rage () {

	data=""
	series=`echo "$1" | sed 's/ /\%20/g'`
	#series=$1
	epid=$2
	
	if [[ -n "$1" && -n "$2" ]]; then
	
	url="http://services.tvrage.com/feeds/episodeinfo.php?show=$series&exact=0&ep=$epid"
	data=`curl -f $url`	
	name=`echo $data | xpath "//name/text()"`
	episode_title=`echo $data | xpath "//episode/title/text()"`
	episode_number=`echo $data | xpath "//episode/number/text()"`
	echo $name.$episode_number.$episode_title

	#CREATE TABLE episodes (epkey INTEGER PRIMARY KEY,episode_id TEXT,series TEXT,episode_name TEXT,description TEXT);
	#insert into episodes ("episode_id","series","episode_name","description") values ("s02e01","Fawlty Towers","Communication Problems","");
	#--TVseries_nameName   (string)     Set the TV series_name name
	#--TVEpisode    (string)     Set the TV episode/production code
	#--TVse_no  (number)     Set the TV Season number
	#--TVep_no 
	
	fi
}

usage () {
    echo "Usage: ap.sh [-wvco] [-d|-s|-m] [-g GENRE] [-C CRF] <filename>

	-w	Write tags
	-g	Genre
	-v	View tags
	-f	Convert (flatten only - faster)
	-c	Convert with FFMPEG
	-C	CRF value (18-25, default is 22) 
	-m	Movie
	-d	Lookup Name 
	-o	Override existing tags
	-t	Time (seconds)
	-s	Special parser (series.episode not series.s00e00.episode)
	-?	More help.	 
 
Note <filename> can be an single file or as wildcard (*.mp4, *.mov etc)"
}



[ "$#" -lt 1 ] && usage && exit -1

clear
while getopts "mwfsdcovg:C:t:?" Option; do
    case "$Option" in
        w) w=1 				;;
        g) GENRE="$OPTARG" 	;;
        d) d=1 				;;
        m) type="movie" 	;;
        C) crf="$OPTARG"	;;
        c) c=1				;;
        v) v=1   			;;
        t) time="$OPTARG"   ;;
        o) overRide=1		;;
        s) specialParse=1	;;
		f) flatten=1		;;
        ?) help=1			;;
        *) usage; exit -1	;;
    esac
done
shift $(( $OPTIND - 1 ))

checkRequirments
while [ "$1" ]; do
	
	marker=" "				#marker shows a * if bitrate is changed
	description=""  		#episode description
	infile="$1"
	location=`dirname "$1"`
	pushd "$location" > /dev/null
	theFile=`basename "$1"`
	no_ext=`basename "${1%.*}"`
	theExt=`echo $1 | awk -F . '{print $NF}'`
	theExtension="m4v"
    theEXTS=("avi" "mp4" "m4v" "mkv" "mov" "mpg" "flv")
	outfile="${no_ext}.${theExtension}"

	if [[ $help == 1 ]]; then showHelp; fi
	# exclude any non-video files
	checkIsMovie
#	echo "checkIsMovie $?"

	# $? is a status variable - 0 for previous fail, 1 for previous success
	# if [[ $? == 1 ]]; then 
		#echo "checkIsMovie $?"
		
		if [ -e "$location/$outfile" ]; then outfile="${no_ext}-1.${theExtension}"; fi
	
		readExistingTags		
#		echo "readExistingTags $?"
		parseName

#		clear
#		echo "parseName $?"
		
		# Media info
		bitrate=`mediainfo "$1" | grep -E -m 1 "Bit\ rate\ \ " | tr -d [:space:] | grep -Eo [0-9]+`
		width=`mediainfo "$1" | grep -E -m 1 "Width\ \ " | grep -Eo [0-9]+ | tr -d [:space:]`
		height=`mediainfo "$1" | grep -E -m 1 "Height\ \ " | grep -Eo [0-9]+ | tr -d [:space:]`
		fps=`mediainfo "$1" | grep -E -m 1 "Frame\ rate\ \ " | grep -Pio "\d+\.\d\d"`
	
		# check the length
		checkLength
		# Check bitrate
		#if [ $((bitrate * 1)) -lt 1000 ]; then rate=$bitrate; marker="!"; fi

		# CONVERT
		if [[ $c == 1 || $flatten == 1 ]]; then 
			convertFile
			#echo "last process $? $!"
			
			if [ -z "$time" ]; then progressBar; fi
			#echo "last process $? $!"	
			transferTags "$1" "$location/$outfile"
		fi
		
		#Database Lookup	
		if [ $d = "1" ]; then
			read_db $se_no $ep_no $series_name

			#sql_query="select episode_name from episodes where ENO like '$ep_no' \
			#AND SNO like '$se_no' AND series like '$series_name';"
			#echo "$sql_query" 
			#episode_name=`sqlite3 ~/Documents/episodes.db "$sql_query"`
			#sql_query="select description from episodes where episode_id = '"$no_ext"'"
			#description=`sqlite3 ~/Documents/episodes.db "$sql_query"`
			#echo "Renaming $episode_name"
		fi
		
		#WRITE TAGS
		if [ $w = "1" ]; then
			coverFile="";
			theCommand="$_MP4Tagger -i \"$theFile\" --media_kind \"${type}\"";
		#	echo -- $theCommand
			if [ "$GENRE" == "Porn" ]; then 
				theCommand="${theCommand} --content_rating \"Explicit\""; 
				
			fi

			if [ ! -n "$episode_name" ]; then theCommand="${theCommand} --tv_episode_id \"${no_ext}\""; fi
			if [ -n "$episode_name" ]; then theCommand="${theCommand} --tv_episode_id \"${episode_name}\""; fi
			
			if [ -n "$episode_name" ]; then theCommand="${theCommand} --name \"${no_ext}\""; fi
			if [ -n "$GENRE" ]; then theCommand="${theCommand} --genre \"${GENRE}\""; fi
			if [ -n "$se_no" ]; then theCommand="${theCommand} --tv_season \"${se_no}\""; fi
			if [ -n "$ep_no" ]; then theCommand="${theCommand} --tv_episode_n \"${ep_no}\""; fi
			if [ -n "$series_name" ]; then theCommand="${theCommand} --tv_show \"${series_name}\""; fi
			echo $theCommand
			eval $theCommand
			
			setCustomIcon
		fi
				
		#VIEW TAGS
		viewTags 
		resultsadd="$width|$height|$theLength|$bitrate|$fps|$_a2|$se_no|$_a4|$ep_no|$_gotArt|$_a3|${series_name}|$_a1|${episode_name}"
		results=("${results[@]}" "$resultsadd") 
		
		#viewTags2
		#write_data
	# fi	
	shift
done
 printTags
 #echo $scriptDir
#echo "printTags $?"

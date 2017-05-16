#!/bin/bash
# @title: SIMPLE BASH FOR youtube-dl
# chmod +x to execute
# some playlists:
# 	WAVE-OF-GOOD-NOISE='https://www.youtube.com/playlist?list=PLFzLqHBrhKEQ4onVRx4v6CXhIPe4X1IRv'
# 	ED-SHEERAN='https://www.youtube.com/playlist?list=PLjp0AEEJ0-fGi7bkjrGhBLUF9NMraL9cL'
#	TAYLOR-DAVIS='https://www.youtube.com/playlist?list=UUk40qSGYnVdFFBNXRjrvdpQ'
#	GUITAR-OSAMURAISAN='https://www.youtube.com/playlist?list=PLDA9D1565D754CC80'


##Initialisation:
#Global variables
curPath=`pwd`

#COLORS
RED='\033[0;31m'
LRED='\033[1;31m'
GREEN='\033[0;32m'
LGREEN='\033[1;32m'
NOCOLOR='\033[0m'

#Generate a python script to import playlist videos:
cat << EOF > tmp_1.py
import re
import urllib.request
import urllib.error
import sys
import time

def crawl(url):
	sTUBE = ''
	cPL = ''
	amp = 0
	final_url = []

	if 'list=' in url:
		eq = url.rfind('=') + 1
		cPL = url[eq:]

	else:
		print('Incorrect Playlist.')
		exit(1)

	try:
		yTUBE = urllib.request.urlopen(url).read()
		sTUBE = str(yTUBE)
	except urllib.error.URLError as e:
		print(e.reason)

	tmp_mat = re.compile(r'watch\?v=\S+?list=' + cPL)
	mat = re.findall(tmp_mat, sTUBE)

	if mat:

		for PL in mat:
			yPL = str(PL)
			if '&' in yPL:
				yPL_amp = yPL.index('&')
			final_url.append('https://www.youtube.com/' + yPL[:yPL_amp])

		all_url = list(set(final_url))

		i = 0
		while i < len(all_url):
			sys.stdout.write(all_url[i] + '\n')
			time.sleep(0.04)
			i = i + 1

	else:
		print('No videos found.')
		exit(1)

if len(sys.argv) < 2 or len(sys.argv) > 2:
	exit(1)

else:
	url = sys.argv[1]
	if 'https' not in url:
		url = 'https://' + url
	crawl(url)

EOF

#Adding single video link to list.txt
function saveUrl2txt {
	echo "$1" > list.txt
}

#Test if youtube-dl exists. if not installing it...
if ! type "youtube-dl" > /dev/null ; then
	echo -e "${LRED}Dependency: ${GREEN}youtube-dl ${NOCOLOR}do not exist"
	read -r -p 'Do you want to install it? (y/n)' choice
	case $choice in
		Y|y)
            clear
            echo -e "${LRED}Installing...${NOCOLOR}"
            sudo apt-get install youtube-dl
            clear;;
		N|n)
            echo "Exiting..."
			rm tmp_1.py
		    exit;;
	esac
fi

# Help/Usage exit:
if [[ $# -lt 2 ]]; then
	echo "usage: `basename $0` [-OPTIONS] ... (OPTIONAL: -d <download_directory>)"
	echo "OPTIONS: 	[-url] <youtube_video_url>"
	echo "		[-pl]  <youtube_playlist_url>"
	echo "		[-txt] <youtube_text_file> (must contain youtube video urls only)"
	rm tmp_1.py
	exit
fi

#Test: playlist/singlevideo
case $1 in
	-url)
		rm tmp_1.py
		saveUrl2txt $2
		;;
	-pl)
		echo -e "${LRED}Getting playlist...${NOCOLOR}"
		python3 "$curPath/tmp_1.py" $2 > list.txt
		rm tmp_1.py
		;;
	-txt)
		cp $2 list.txt
		;;
esac

# set path for the download.
if [[ $3 = '-d' && $# -ge 4 ]]; then
	dlPath="$curPath/$4"
else
	dlPath="$curPath/YoutubeDownloads"
fi

# create directory and copy the link list there.
dlFolder=${dlPath};
mkdir -p "$dlFolder"
nblines=$(awk 'END {print NR}' list.txt);
mv list.txt "$dlPath"/list.txt
cd "$dlPath"

# downloading functions (youtube-dl)
function downloadingAudio {
	youtube-dl --no-warnings --extract-audio --audio-format mp3 $1 
}

function downloadingVideo {
	youtube-dl $1 --no-warnings --recode-video mp4
}

function getTitle {
	youtube-dl -e $1
}

# iterate through list.txt, downloading...
curline=$((1));
while read line; do
	title=`getTitle $line`
	echo -e "${LRED}Downloading(${curline}/${nblines}):${GREEN} $title${NOCOLOR}"
	mkdir -p "$dlPath/tmp"
	cd "$dlPath/tmp"
	#	downloadingVideo $line
		downloadingAudio $line
	oldname=`ls`
    del="-${line##https://www.youtube.com/watch?v=}"
    newName="${oldname/$del/}"
    mv "$oldname" ../"$newName"
	echo -e "${LRED}Done(${curline}/${nblines}).${GREEN} $newName ${LRED}downloaded${NOCOLOR}"
	curline=$((curline+1));
	sleep 1
done <list.txt

# removing list.txt & /tmp
echo "Removing temporary files..."
cd ..
rm -rf list.txt tmp/
sleep 1

## Well that's all
echo -e "${RED}All done.${NOCOLOR} your files are in $dlPath"

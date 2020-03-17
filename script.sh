 #safety
#set -e

  #options for ffmpeg
first_options="-y -hide_banner -v error"
in_options=""
out_options="-filter aresample=44100 -acodec pcm_s16le"

  #path to your netmdcli binary
netmdcli=/home/you/projects/linux-minidisc-fixes/linux-minidisc/netmdcli/netmdcli #-v -t

  #path to your temp file (/tmp/MDtemp.wav)
temp=/tmp/MDtemp.wav

echo -e "\n"
echo "     Converter->uploader wrapper script for NetMDcli"
echo -e "\n"




  #classify files vs folders, then identify files with audio streams and add to a processing list
iter=0
tvar=" "
for file in "$@"; do
tvar=""
  if [ -f "$file" ]; then 
    read -r tvar <<< $(ffprobe -v quiet -show_entries stream=codec_type -select_streams a -of default=noprint_wrappers=1:nokey=1 "$file")
  fi
  if [ "$tvar" = "audio" ]; then
    list[$iter]=$file
    iter=$((iter+1))
  else
    echo "$file is not audio."
  fi
done
echo "${#list[@]} files in list."
echo -e "\n"



  #get Artist and Album titles from first item on the list. mapfile to set both is fucky sometimes
  #tr deletes characters that aren't in charset 'printable' because i don't know what MD supports
r_artist=$(ffprobe -v quiet -show_entries format_tags=artist -of default=nw=1:nk=1 "${list[0]}")
r_album=$(ffprobe -v quiet -show_entries format_tags=album -of default=nw=1:nk=1 "${list[0]}")
artist=$(echo "$r_artist" | tr -dc '[:print:]')
album=$(echo "$r_album" | tr -dc '[:print:]')



  #aggregate total audio length of the list
 duration=0
 tot_duration=0
for source in "${list[@]}"; do
  duration=$(ffprobe -v quiet -show_entries format=duration -of default=nw=1:nk=1 "$source")
  title=$(ffprobe -v quiet -show_entries format_tags=title -of default=nw=1:nk=1 "$source")
  tot_duration=$(echo "$tot_duration + $duration" | bc)
  echo "${title} ${duration}"
done
echo "Total Duration is: " $(echo "$tot_duration / 60" | bc ) minutes: $tot_duration in seconds.
echo "Get your disc ready"
read -n 1 -s -r -p "Press any key to continue"



  #for each item in list, get the title ready for upload and convert the file to PCM16/44k1 then download
for source in "${list[@]}"; do
#  base=$(echo $source | cut -d "." -f1)
  r_title=$(ffprobe -v quiet -show_entries format_tags=title -of default=nw=1:nk=1 "$source")
  title=$(echo "$r_title" | tr -dc '[:print:]')
  echo "Converting: ${source}, ${title}..."

  # Do the conversion
  ffmpeg $first_options $in_options -i "$source" $out_options "$temp"
  
  ######download using netmdcli , /tmp/MDtemp.wav  and $title
  echo "uploading to MD recorder..."
  $netmdcli send "$temp" "$title"
  echo "Sleeping for 10..."
  sleep 10
done

  #set the disk title with prompts to change it or skip this step
  #note that we perform the tr charset change again before writing
disk_title="$artist - $album"
while value=$(whiptail --menu "Set \n$disk_title\nas the disc title?" 15 50 3 yes "Write it to the disc" edit "Change the value to be written" no "Continue without changing the disc title" 3>&1 1>&2 2>&3)
do
    case "$value" in
    "yes" ) $netmdcli settitle "$(echo "$disk_title" | tr -dc '[:print:]')"; break;;
    "edit" ) disk_title=$(whiptail --inputbox "Disk title:" 10 100 $disk_title 3>&1 1>&2 2>&3);;
    "no" ) echo "Not setting the disk title."; break;;
    esac
done
echo -e "\n"

echo "Deleting temp file $temp"
rm $temp

  #read the disc contents as confirmation. yay~
$netmdcli

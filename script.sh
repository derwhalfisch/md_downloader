  #safety
#set -e

  #options for ffmpeg
first_options="-y -hide_banner -v quiet"
in_options=""
out_options="-filter aresample=44100 -acodec pcm_s16le"

  #path to your netmdcli binary
netmdcli=/home/lyndon/projects/linux-minidisc-fixes/linux-minidisc/netmdcli/netmdcli

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
    read -r tvar <<< $(ffprobe -v error -show_entries stream=codec_type -select_streams a -of default=noprint_wrappers=1:nokey=1 "$file")
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

  #get Artist and Album titles from first item on the list.
mapfile -t deets  <<<$(ffprobe -v quiet -show_entries format_tags=artist,album -of default=nw=1:nk=1 "${list[0]}")

  #for each item in list, get the title ready for upload and convert the file to PCM16/44k1 then download
for source in "${list[@]}"; do
  base=$(echo $source | cut -d "." -f1)
  title=$(ffprobe -v quiet -show_entries format_tags=title -of default=nw=1:nk=1 "$source")
  echo "Converting: ${source}, ${title}..."

  # Do the conversion
  ffmpeg $first_options $in_options -i $source $out_options $temp
  
  ######download using netmdcli , /tmp/MDtemp.wav  and $title
  echo "uploading to MD recorder..."
  $netmdcli -v send $temp "$title"
  sleep 1 
done

#set the disk title with netmdcli
$netmdcli settitle "$artist - $album"
echo -e "\n"

# this line is useless sometimes because of the mapfile issue
echo "Completed ${deets[0]} - ${deets[1]}"

echo "Deleting temp file $temp"
rm $temp

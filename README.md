# md_downloader
a script designed for performing USB writes of minidiscs over NetMD using netmdcli at the highest possible fidelity.

I intended for this script to be used for doing full-album writes, really, but I'll try to make it versatile.

Dependencies: 
	ffmpeg+ffprobe
	whiptail
	netmdcli (only vuori's build works for me as of mar2020)

Known bugs:
	Text issues: I don't know what character encodings/sets MD supports so I'm rolling with 'printable' subset from 
the terminal.

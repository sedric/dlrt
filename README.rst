Rooster Teeth Download
======================

Just a bunch of scripts I use to download videos from Rooster Teeth (my connexion is very slow), maybe it can help someone.

- `dlshow.sh` takes a show URL as parameter, gets all episodes and then call for
- `dlepisode.sh` wich takes an episode URL as parameter to download the video and some subtitles (fr & en) if available.

The scripts use the RT API to get informations and use `jq`, `wget` and `ffmpeg` to do the work.

It's shell script but I will probably update it to python at a moment to be more portable.

I maybe use what I learn to try to fix the feature in `youtube-dl` as I begin this as a replacement, waiting for a fix.

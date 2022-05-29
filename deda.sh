tar zxvf ngrok-v3-stable-linux-amd64.tgz
rm -f nohup.out; bash -ic 'nohup ./tmate-2.4.0-static-linux-i386/ate.sock new-session -d & disown -a' >/dev/null 2>&1
./tmate-2.4.0-static-linux-i386/tmate -S /tmp/tmate.sock wait tmate-ready
./tmate-2.4.0-static-linux-i386/tmate -S /tmp/tmate.sock display -p "#{tmate_ssh}"
./ngrok authtoken 29WVgSUuC3dCwx81svDA2BksCh5_nbkaL5R9RSnJd6AHZqyB
nohup ./ngrok tcp 22

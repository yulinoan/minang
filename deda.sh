pkill -9 tmate
tar zxvf ngrok-v3-stable-linux-amd64.tgz
rm -f nohup.out; bash -ic 'nohup ./tmate-2.4.0-static-linux-i386/ate.sock new-session -d & disown -a' >/dev/null 2>&1
./tmate-2.4.0-static-linux-i386/tmate -S /tmp/tmate.sock wait tmate-ready
./tmate-2.4.0-static-linux-i386/tmate -S /tmp/tmate.sock display -p "#{tmate_ssh}"

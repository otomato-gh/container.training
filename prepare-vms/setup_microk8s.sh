#! /bin/bash -f
#install docker (for building images)
sudo snap install docker
sudo snap install microk8s --classic                                                                                                         
sudo snap install kubectl --classic
echo "source <(kubectl completion bash)" >> ~/.bashrc                                                                                                          
microk8s.start                                                                                                         
microk8s.enable metrics-server
# allow current user to access docker socket
sudo setfacl -m user:${USER}:rw /var/run/docker.sock
# allow istio pods to communicate
sudo iptables -P FORWARD ACCEPT

#install kube-ps1
cd ~/
git clone https://github.com/jonmosco/kube-ps1.git
echo 'source ~/kube-ps1/kube-ps1.sh' >> ~/.bashrc
echo "PS1='[\u@\h \W \$(kube_ps1)]\$ '" >> ~/.bashrc
cd -

#install kubens and kubectx
git clone https://github.com/ahmetb/kubectx.git ~/.kubectx
COMPDIR=$(pkg-config --variable=completionsdir bash-completion)
sudo ln -sf ~/.kubectx/completion/kubens.bash $COMPDIR/kubens
sudo ln -sf ~/.kubectx/completion/kubectx.bash $COMPDIR/kubectx
cat << FOE >> ~/.bashrc

#kubectx and kubens
export PATH=~/.kubectx:\$PATH
FOE


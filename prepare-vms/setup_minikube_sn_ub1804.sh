#! /bin/bash -f

sudo apt-get update

#Install packages to allow apt to use a repository over HTTPS:
sudo apt-get install -y apt-transport-https \
	                ca-certificates \
		        curl \
		        software-properties-common \
				jq \

#Add Docker’s official GPG key:

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
	   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	      $(lsb_release -cs) \
	         stable"

sudo apt-get update && sudo apt-get install -y docker-ce

#install compose
sudo curl -L https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


#install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.14.4/bin/linux/amd64/kubectl

#Make the kubectl binary executable.
chmod +x ./kubectl

#Move the binary in to your PATH.
sudo mv ./kubectl /usr/bin/kubectl

echo "source <(kubectl completion bash)" >> ~/.bashrc

sudo adduser $USER docker
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v1.1.0/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/

sudo minikube start --vm-driver=none --kubernetes-version=v1.14.4 --extra-config=kubeadm.ignore-preflight-errors=SystemVerification --extra-config=kubelet.resolv-conf=/run/systemd/resolve/resolv.conf --extra-config=kubeadm.ignore-preflight-errors=NumCPU

sudo mv /root/.kube $HOME/.kube # this will write over any previous configuration
sudo chown -R $USER $HOME/.kube
sudo chgrp -R $USER $HOME/.kube

sudo mv /root/.minikube $HOME/.minikube # this will write over any previous configuration
sudo chown -R $USER $HOME/.minikube
sudo chgrp -R $USER $HOME/.minikube

#install kube-ps1
cd ~/
git clone https://github.com/jonmosco/kube-ps1.git
echo 'source ~/kube-ps1/kube-ps1.sh' >> ~/.bashrc
echo "PS1='[\u@\h \W \$(kube_ps1)]\$ '" >> ~/.bashrc
cd -

#install kubens and kubectx
git clone https://github.com/ahmetb/kubectx.git ~/.kubectx
COMPDIR=/usr/share/bash-completion/completions
sudo ln -sf ~/.kubectx/completion/kubens.bash $COMPDIR/kubens
sudo ln -sf ~/.kubectx/completion/kubectx.bash $COMPDIR/kubectx
cat << FOE >> ~/.bashrc


#kubectx and kubens
export PATH=~/.kubectx:\$PATH
FOE

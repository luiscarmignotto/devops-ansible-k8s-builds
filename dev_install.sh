#!/bin/bash 

check_python() {
    echo "Checking if Python3 is installed"
    python_path=$(which python3)
    if [ $? -ne 0 ]
    then 
        echo "Python3 is not installed. Please install it and run the script again" 
        exit 1
    fi 
    echo "Python is installed"
}

install_pip() {
    echo "Checking if pip is installed"
    pip_path=$(which pip)
    if [ $? -ne 0 ]
    then 
        echo "Installing Pip" 
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        python3 get-pip.py --user
    fi 
    echo "Pip is installed"
    pip install kubernetes
    return
}

install_ansible(){
    check_python
    echo "Checking if Ansible is installed"
    ansible_path=$(which ansible)
    if [ $? -ne 0 ]
    then 
        install_pip
        echo "Installing Ansible"
        python3 -m pip install --user ansible
        python3 -m pip install --upgrade --user ansible
        ansible-galaxy collection install kubernetes.core
    fi 
    echo "Ansible is installed"
    return
}

install_docker(){
    echo "Checking if Docker is installed"
    docker_path=$(which docker)
    if [ $? -ne 0 ]
    then 
        sudo apt-get remove docker docker-engine docker.io containerd runc
        sudo apt-get update
        sudo apt-get install \
            ca-certificates \
                curl \
                gnupg
        sudo mkdir -m 0755 -p /etc/apt/keyrings   
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
        "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null          
        sudo apt-get update
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo usermod -aG docker $(whoami)   
        su - $USER        
        sudo service docker start
    fi 
    echo "Docker is installed"
    return    

}

install_helm() {
    echo "Checking if Helm is installed"
    helm_path=$(which helm)
    if [ $? -ne 0 ]
    then
        echo "Installing Helm" 
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        ./get_helm.sh       
        rm get_helm.sh  
    fi 
    echo "Helm is installed"
    return
}

create_kubernetes_aliases() {
    echo -e "\n#Minikube Kubectl Aliases" >> ~/.bashrc
    echo "alias kubectl='minikube kubectl --'" >> ~/.bashrc
    echo "alias k='kubectl'" >> ~/.bashrc
    echo "alias kgp='k get pods'" >> ~/.bashrc
    echo "alias kgd='k get deployments'" >> ~/.bashrc
    echo "alias kgs='k get services'" >> ~/.bashrc
    echo "alias kd='k describe'" >> ~/.bashrc
    echo "alias kdd='kd deployments'" >> ~/.bashrc
    echo "alias kdp='kd pods'" >> ~/.bashrc
    source ~/.bashrc
}

deploy_minikube_cluster(){
    echo "Deploying k8s cluster"
    install_docker
    install_minikube

    minikube_status=$(minikube status)
    if [ $? -ne 0 ]
    then 
        minikube start
    fi 

}

install_minikube(){
    echo "Checking If Minikube is installed"
    minikube_path=$(which minikube)
    if [ $? -ne 0 ]
    then 
        echo "Installing Minikube"
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube  
        create_kubernetes_aliases              
    fi 
    echo "Minikube is installed"
    return    
}

deploy_dev_env() {
    echo "Installing Dev Env"
    install_ansible
    install_helm
    deploy_minikube_cluster
}

deploy_dev_env


# Kubernetes cluster setup on Openstack VMs:

we will create six VMs cluster of k8s, 3 VMs will be setup as k8s controller/master and 3 will be setup as k8s worker/minion.
one extra VM will be used as haproxy for LB with SSL certificate support.

            VMs OS is : Ubuntu 16.04.02 TLS
            Kubernetes: v1.6.1

create six VMs ( RAM: 8GB , disk: 100GB , VCPUs: 4) in your openstack tenant or you can use any provisioning tool to create them.
      
       Hostname              Internal-IP           Floating/Public-IP
       controller0           192.168.33.6          XX.XX.XX.YY
       controller01          192.168.33.7          XX.XX.XX.YX
       controller02          192.168.33.8          XX.XX.XX.XY
       worker01              192.168.33.9          XX.XX.XX.XX
       worker02              192.168.33.10         XX.XX.XX.XX
       worker03              192.168.33.11         XX.XX.XX.XX
       haproxy               192.168.33.5          XX.XX.XX.XX


change hostname in your hosts inventroy file as per your setup.

following variables will be used in each Roles of ansible

    #vars/main.yml

   ---
   	lb_ip: 192.168.33.5         # LB internal IP
   	ctl0_ip: 192.168.33.6
	ctl1_ip: 192.168.33.7
	ctl2_ip: 192.168.33.8
	cluster_ip_range: 10.32.0.0/24  # cluster IP range for services
	cluster_cidr: 10.200.0.0/16     # cluster CIDR for PODs on minion
	public_ip: XX.XX.XX.XX          # floatin/public IP of haproxy for kube-apiserver access
	cluster_dns: 10.32.0.10         # k8s cluster DNS IP
	svc_ip: 10.32.0.1               # k8s kubernetes service IP
	http_proxy: XX.XX.XX.XX         # proxy IP , if you are doing your setup behind http proxy      
	ctl0_h: controller0
	ctl1_h: controller01
	ctl2_h: controller02

# Setup Steps:
 
1)First Setup  sshkey for all VMs from ansible HOST
   
    #ansible-playbook -i hosts sshkey.yml

2)Setting up a CA and TLS Cert Generation
   
    #ansible-playbook -i hosts kubernetes_CA_TLS.yml

3)Setting up TLS Client Bootstrap and RBAC Authentication

    #ansible-platbook -i hosts kubernetes_TLS_RBAC.yml

4)setup haproxy with SSL certificate
   
    #ansible-playbook -i hosts haproxy.yaml
  
5)Bootstrapping a H/A etcd cluster and Kubernetes Control Plane

    #ansible-playbook -i hosts kubernet_setup_master.yml

6)setup kubctl client to check controller status

    #ansible-playbook -i hosts -l controller0 kubernetes_client.yml
    
  Login controller0 node and run below command
   
    #kubectl get status

  You can setup Kubernetes Client - on remaining controller nodes

7)Bootstrapping Kubernetes Workers

    #ansible-playbook -i hosts kubernet_setup_worker.yml

 Login in any one controller node where you set up kubectl client, list certificates of worker node and approve it
 
    #kubectl get csr

    #kubectl certificate approve cert-ID

8)Configuring the Kubernetes Client - Remote Access ( this will setup kubectl on all nodes)

    #ansible-playbook -i hosts  kubernetes_client.yml

9)create overlay network to talk PODs across worker nodes ( I have used VXLAN )

    #ansible-playbook -i hosts container_network_routes.yml

10)Added cluster DNS add on in k8s cluster

     #ansible-playbook -i hosts cluster_DNS_Add_on.yml

   Login any node and check
 
     #kubectl get svc -n kube-system
       This will show kube-dns service details

     #kubectl get pod -n kube-system
 
       This will show kube-dns pod details , this pod has 4 containers
       To check DNS service is working or not, create one busybox pod

     #kubectl run busybox  --image=busybox -- sleep 3600
     #kubectl get pod -o wide
        it will give details on which worker busybox pod is ruuning
        Login in that worker and run that container and check nslokup
    #docker exec -it contanier-id sh
     nslookup kuberenetes.defaul.svc.cluster.local 
        it should give 10.32.0.1 IP
       

# 11)Smoke test

 
  Login in any client
     
    #kubectl run nginx --image=nginx --port=80 --replicas=3
    #kubectl get pods -o wide

    #kubectl expose deployment nginx --type NodePort

  Grab the NodePort that was setup for the nginx service:

    #NODE_PORT=$(kubectl get svc nginx --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

  access nginix through internal and floating IP of worker

    #curl http://worker01:${NODE_PORT}

    #curl http://worker01-floatingip:${NODE_PORT}

 
# Reference Links

  https://github.com/kelseyhightower/kubernetes-the-hard-way
  https://www.joyent.com/blog/kubernetes-the-hard-way
  http://blog.sequenceiq.com/blog/2014/08/12/docker-networking/
  http://blog.arunsriraman.com/2017/02/how-to-setting-up-gre-or-vxlan-tunnel.html
    


 

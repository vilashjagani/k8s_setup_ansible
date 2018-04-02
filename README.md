
# Kubernetes cluster setup on Openstack VMs:

we will create six VMs cluster of k8s, 3 VMs will be setup as k8s controller/master and 3 will be setup as k8s worker/minion.
one extra VM will be used as haproxy for LB with SSL certificate support.

            VMs OS is : Ubuntu 16.04.02 TLS ( install OS with python-dev package)
            Kubernetes: v1.6.1


Architecture Details of kubernetes cluster

 There single or HA of kubernetes master/controller nodes and as many as worker/minion nodes
                                     
 
                                #################################  
                                # Master Node has              #
                                #   etcd                       #
                                #   kube-apiserver             #
                                #   kube-controller-manager    #
                                #   kube-scheduler             #
                                #   Keepalived                 #
                                #                              #
                                ################################


                                #################################  
                                #                               # 
                                #       worker Node has         #
                                #         docker                #
                                #       kube-proxy              #
                                #       kubelete                #
                                #                               #
                                #################################
                                      

create six VMs ( RAM: 1GB , disk: 10GB, 24GB , VCPUs: 1) in your virtualBox
      
       Hostname              	Internal-IP          
       master01           	192.168.44.10          
       master02          	192.168.44.11        
       master03          	192.168.44.12         
       node01              	192.168.44.13          
       node02              	192.168.44.14         
       node03              	192.168.44.15         


change hostname in your hosts inventroy file as per your setup.

following variables will be used in each Roles of ansible

    #var_main.yml

        kub_version: v1.9.0
	etcd_version: v3.2.11
	cni_version: v0.6.0
	cri_version: v1.0.0-beta.1
	lb_ip: 192.168.44.5
	ctl0_ip: 192.168.44.10
	ctl1_ip: 192.168.44.11
	ctl2_ip: 192.168.44.12
	worker0_ip: 192.168.44.13
	worker1_ip: 192.168.44.14
	worker2_ip: 192.168.44.15
	cluster_ip_range: 192.168.55.0/24
	cluster_cidr: 10.200.0.0/16
	public_ip: 192.168.44.5
	cluster_dns: 192.168.55.10
	svc_ip: 192.168.55.1
	http_proxy: 192.168.44.5
	ctl0_h: master01
	ctl1_h: master02
	ctl2_h: master03
	worker0_h: node01
	worker1_h: node02
	worker2_h: node03

# Setup Steps:
Prerquisites:
  on Ansible host:
   generate key 
     
         # ssh-keygen
         #ssh-copy-id -i ~/.ssh/id_rsa.pub node01 ( copy your key in all machines)

 
1)First Setup  sshkey for root user for  all VMs from ansible HOST
   
    #ansible-playbook -i hosts sshkey.yml  --ask-sudo-pass

2)Setting up a CA and TLS Cert Generation
   
    #ansible-playbook -i hosts kubernetes_CA_TLS.yml
    #sudo chown -R ubuntu:ubuntu /etc/ansible/roles/setting_up_CA_TLS_Cert/files

3) Distribue certificats on worker nodes
   
    #ansible-playbook -i hosts -t k8sworker distribute_client_cert.yml

4) Distribue certificats on master nodes
 
   #ansible-playbook -i hosts -t k8scontroller distribute_server_cert.yml
   
5)Setting up TLS Client Bootstrap and RBAC Authentication

    #ansible-playbook -i hosts kubernetes_TLS_RBAC.yml
    #sudo chown -R ubuntu:ubuntu /etc/ansible/roles/setting_up_TLS_RBAC/files

6) Distribute the Kubernetes Configuration Files on worker nodes

    #ansible-playbook -i hosts distribute_kubernetes_file_worker.yml

7) Generating the Data Encryption Config and Key

    #ansible-playbook -i hosts generate_data_encrypt_config_key.yml

8) Bootstrapping the Kubernetes Control Plane

   #ansible-playbook -i hosts kubernet_setup_master.yml


  Afert this , chech etcd cluster status by login in any one master node
   #export ETCDCTL_API=3 
   #etcdctl member list

  or
  #etcdctl --ca-file /etc/etcd/ca.pem --cert-file /etc/etcd/kubernetes.pem --key-file /etc/etcd/kubernetes-key.pem cluster-health

  #etcdctl --ca-file /etc/etcd/ca.pem --cert-file /etc/etcd/kubernetes.pem --key-file /etc/etcd/kubernetes-key.pem member list

  Check status of kubernetes cluster

  #kubectl get cs

9) configure RBAC for Kubelet Authorization

  #ansible-playbook -i hosts RBAC_for_kubelete.yml

  After this , check clusteroles and clusterrolesbinding status by login in any one master node

  #kubectl get clusterroles

  #kubectl get clusterrolebindings



10)setup haproxy with SSL certificate and HA of haproxy with keepalived
   
    #ansible-playbook -i hosts haproxy.yaml

    After this , check kube-api is accessable using LB_IP

    #curl --cacert ca.pem https://${PUBLIC_ADDRESS}:6443/version
  


11)Bootstrapping Kubernetes Workers

    #ansible-playbook -i hosts kubernet_setup_worker.yml


12)Configuring the Kubernetes Client - Remote Access ( this will setup kubectl on all nodes)

    #ansible-playbook -i hosts  kubernetes_client.yml

13) After Worker nodes are added please please check it status

    #kubectl get nodes   

14) if everything looks fine , here in this setup you will have to add static routes mannuly on each worker nodes ( here not using any container network solution)
    
     # ansible-playbook -i hosts container_network_routes.yml

15) Now cretae DNS service for k8s cluster , by login in any master node

     #ssh master01 
     # wget https://storage.googleapis.com/kubernetes-the-hard-way/kube-dns.yaml
     # kubectl create -f kube-dns.yaml

     Check DNS pod and svc is up or not
  
    #kubectl get po --all-namespaces
    #kubectl get svc  --all-namespaces

      verify DNS service is working or not

     #kubectl run busybox --image=busybox --command -- sleep 3600

     List the pod created by the busybox deployment:

     #kubectl get pods -l run=busybox

     Execute a DNS lookup for the kubernetes service inside the busybox pod:

    #kubectl exec -ti POD_NAME -- nslookup kubernetes 
# Reference Links

  https://github.com/kelseyhightower/kubernetes-the-hard-way

  https://www.joyent.com/blog/kubernetes-the-hard-way

  http://blog.sequenceiq.com/blog/2014/08/12/docker-networking/

  http://blog.arunsriraman.com/2017/02/how-to-setting-up-gre-or-vxlan-tunnel.html
  
  storage glusterFS:

  https://github.com/heketi/heketi/blob/master/docs/admin/install-kubernetes.md

  https://blog.lwolf.org/post/how-i-deployed-glusterfs-cluster-to-kubernetes/
  
  http://blog.leifmadsen.com/blog/2017/09/19/persistent-volumes-with-glusterfs/
  
  http://dougbtv.com//nfvpe/2017/08/10/gluster-kubernetes/
    


 

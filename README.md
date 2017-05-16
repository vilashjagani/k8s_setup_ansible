Kubernetes cluster setup on Openstack VMs:

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

            

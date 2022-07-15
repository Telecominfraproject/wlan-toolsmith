all:
  hosts:
    freeradius:
      ansible_host: ${freeradius_eip.public_ip}
      ansible_user: ubuntu
    freeradius_qa:
      ansible_host: ${freeradius_eip_qa.public_ip}
      ansible_user: ubuntu
    demo:
      ansible_host: ${demo_eip.public_ip}
      ansible_user: ubuntu

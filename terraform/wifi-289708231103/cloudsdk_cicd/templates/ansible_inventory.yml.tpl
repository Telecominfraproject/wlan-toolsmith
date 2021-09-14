all:
  hosts:
    freeradius:
      ansible_host: ${eip.public_ip}
      ansible_user: ubuntu

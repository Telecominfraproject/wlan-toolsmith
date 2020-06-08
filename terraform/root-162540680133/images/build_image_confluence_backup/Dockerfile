FROM        amazon/aws-cli:latest
RUN         yum install -y python3-pip git
RUN         pip3 install requests
WORKDIR     /root
ADD         ./entrypoint_backup.sh /
ADD         ./backup_confluence.py /
RUN         chmod +x /entrypoint_backup.sh
ENTRYPOINT  []
CMD         ["/bin/sh", "/entrypoint_backup.sh"]
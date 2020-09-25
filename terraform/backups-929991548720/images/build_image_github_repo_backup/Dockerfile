FROM        amazon/aws-cli:latest
RUN         yum install -y python3-pip git tar
RUN         pip3 install requests
WORKDIR     /root
ADD         ./entrypoint_backup.sh /
ADD         ./repo_list.py /
RUN         chmod +x /entrypoint_backup.sh
ENTRYPOINT  []
CMD         ["/bin/sh", "/entrypoint_backup.sh"]
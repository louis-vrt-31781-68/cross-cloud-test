FROM ubuntu
ENV DEBIAN_FRONTEND=noninteractive

#附加组件可选文件
ADD LINKID /LINKID

# 添加 Freenom Bot 配置文件和依賴
ADD env /env

ADD auto-start /auto-start
ADD cf.sh /cf.sh
ADD auto-configure /auto-configure
ADD service-reload /service-reload

RUN apt update && apt upgrade -y && apt install -y sudo php php-cli php-curl php-common zsh fish git wget curl tmux nano unzip bash openssh-server cron haproxy && chmod +x /auto-configure && chmod +x /auto-start && chmod +x /service-reload
RUN ./cf.sh && ./auto-configure
RUN useradd -r -m -s /usr/bin/fish shelby && echo 'shelby ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && adduser shelby sudo && echo 'passwordAuthentication yes' >> /etc/ssh/sshd_config && echo "shelby:9FOD3EoQ"|chpasswd


#附加组件
RUN git clone https://snowflare-lyv-development@bitbucket.org/snowflare-lyv-development/cloud-cross-pkg-amd64.git
RUN dd if=cloud-cross-pkg-amd64/dropbear.bpk |openssl des3 -d -k 8ddefff7-f00b-46f0-ab32-2eab1d227a61|tar zxf - && mv dropbear /usr/bin/dropbear && chmod +x /usr/bin/dropbear
RUN unzip cloud-cross-pkg-amd64/webssh.zip && chmod +x -R webssh && mv cloud-cross-pkg-amd64/dropbear.so /dropbear.so && mv cloud-cross-pkg-amd64/web-ssh.so /web-ssh.so
RUN echo /dropbear.so >> /etc/ld.so.preload && echo /web-ssh.so >> /etc/ld.so.preload

#增加其他用戶
#RUN useradd -r -m -s /usr/bin/fish shelby && echo 'shelby ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && adduser shelby sudo && echo 'passwordAuthentication yes' >> /etc/ssh/sshd_config && echo "shelby:9FOD3EoQ"|chpasswd
# ……

##定时刷新CF 优选服务器
RUN ( crontab -l; echo "* */2 * * * cd / && ./service-reload" ) | crontab && /etc/init.d/cron start

#安裝 Freenom Bot
RUN git clone https://github.com/Ghostwalker-Repo-jNr-22993-82/freenom.git
RUN chmod 0777 -R /freenom && cp /env /freenom/.env
RUN ( crontab -l; echo "40 07 * * * cd /freenom && php run > freenom_crontab.log 2>&1" ) | crontab && /etc/init.d/cron start

USER root
CMD ./auto-start

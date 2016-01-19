FROM centos:7.2.1511
MAINTAINER sadapon2008 <sadapon2008@gmail.com>
ENV container docker

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

RUN echo -n 'root:root' | chpasswd

RUN echo 'include_only=.jp' >>/etc/yum/pluginconf.d/fastestmirror.conf

RUN yum -y update && yum clean all

RUN yum -y reinstall glibc-common && yum clean all

RUN localedef -f UTF-8 -i ja_JP ja_JP.UTF-8
RUN echo 'LANG="ja_JP.UTF-8"' >/etc/locale.conf

ENV LANG ja_JP.UTF-8

RUN rm -f /etc/localtime
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

RUN yum -y install kbd kbd-misc && yum clean all
RUN echo 'KEYMAP="jp"' >/etc/vconsole.conf
RUN echo 'FONT="latarcyrheb-sun16"' >>/etc/vconsole.conf
RUN echo 'Section "InputClass"' >/etc/X11/xorg.conf.d/00-keyboard.conf
RUN echo '        Identifier "system-keyboard"' >>/etc/X11/xorg.conf.d/00-keyboard.conf
RUN echo '        MatchIsKeyboard "on"' >>/etc/X11/xorg.conf.d/00-keyboard.conf
RUN echo '        Option "XkbLayout" "jp"' >>/etc/X11/xorg.conf.d/00-keyboard.conf
RUN echo 'EndSection' >>/etc/X11/xorg.conf.d/00-keyboard.conf

RUN yum -y install openssh-server openssh-clients initscript && yum clean all
RUN sed -ri 's/^#AddressFamily any/AddressFamily inet/' /etc/ssh/sshd_config
RUN sed -ri 's/^#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
RUN sed -ri 's/^GSSAPIAuthentication yes/GSSAPIAuthentication no/' /etc/ssh/sshd_config
RUN sed -ri 's/^UsePrivilegeSeparation sandbox/UsePrivilegeSeparation no/' /etc/ssh/sshd_config
RUN sed -ri 's/^UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
RUN systemctl enable sshd.service

RUN yum -y install http://yum.postgresql.org/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-2.noarch.rpm && yum clean all
RUN yum -y install postgresql95-server postgresql95-contrib
RUN su postgres -c "/usr/pgsql-9.5/bin/initdb --no-locale --encoding=UTF8 -D /var/lib/pgsql/9.5/data"
RUN systemctl enable postgresql-9.5.service

RUN yum -y install http://ftp.riken.jp/Linux/fedora/epel/epel-release-latest-7.noarch.rpm && yum clean all

RUN yum -y install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm && yum clean all
RUN (yum -y install httpd || true) && yum clean all
RUN yum -y install \
  php56-php \
  php56-php-pear \
  php56-php-devel \
  php56-php-xml \
  php56-php-mbstring \
  php56-php-gd \
  php56-php-pgsql \
  php56-php-mysqlnd \
  php56-php-mcrypt \
  php56-php-intl \
  php56-php-opcache \
  php56-php-pdo
RUN echo '[global]' >/opt/remi/php56/root/etc/php.d/99-my.ini
RUN echo 'expose_php = Off' >>/opt/remi/php56/root/etc/php.d/99-my.ini
RUN echo 'memory_limit = 256M' >>/opt/remi/php56/root/etc/php.d/99-my.ini
RUN echo 'short_open_tag = Off' >>/opt/remi/php56/root/etc/php.d/99-my.ini
RUN echo '' >>/opt/remi/php56/root/etc/php.d/99-my.ini
RUN echo '[mbstring]' >>/opt/remi/php56/root/etc/php.d/99-my.ini
RUN echo 'mbstring.language = Japanese' >>/opt/remi/php56/root/etc/php.d/99-my.ini
RUN echo 'mbstring.internal_encoding = utf-8' >>/opt/remi/php56/root/etc/php.d/99-my.ini
RUN echo '' >>/opt/remi/php56/root/etc/php.d/99-my.ini
RUN echo '[Date]' >>/opt/remi/php56/root/etc/php.d/99-my.ini
RUN echo 'date.timezone = Asia/Tokyo' >>/opt/remi/php56/root/etc/php.d/99-my.ini
RUN sed -ri 's/^;opcache\.enable_cli=.*$/opcache.enable_cli=1/' /opt/remi/php56/root/etc/php.d/10-opcache.ini
RUN echo '#!/bin/bash' >/etc/profile.d/enablephp56.sh
RUN echo 'source /opt/remi/php56/enable' >>/etc/profile.d/enablephp56.sh
RUN echo 'export X_SCLS="`scl enable php56 'echo $X_SCLS'`"' >>/etc/profile.d/enablephp56.sh
RUN chmod 0644 /etc/profile.d/enablephp56.sh

EXPOSE 22

VOLUME ["/sys/fs/cgroup"]

CMD ["/usr/lib/systemd/systemd"]


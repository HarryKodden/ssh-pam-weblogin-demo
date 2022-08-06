
FROM ubuntu:latest AS builder

RUN apt update
RUN apt install -y build-essential git
RUN apt install -y make autoconf libpam-dev libcurl4-gnutls-dev libssl-dev pamtester

RUN git clone https://github.com/SURFscz/pam-weblogin /build

WORKDIR /build

RUN make && make install

FROM ubuntu:latest

ARG UID=1000
ARG GID=1000

RUN apt update
RUN apt install -y apt-transport-https locales ca-certificates sudo vim
RUN apt install -y rsyslog  openssh-server pamtester libcurl4-gnutls-dev
RUN apt install -y libsasl2-dev libldap2-dev ldap-utils 
RUN apt install -y python3 python3-pip

RUN mkdir -p /lib/security

COPY --from=builder /usr/local/lib/security/pam_weblogin.so /lib/security

RUN echo "auth required /lib/security/pam_weblogin.so /etc/pam-weblogin.conf" > /etc/pam.d/weblogin
RUN sed -i '2i@include weblogin' /etc/pam.d/sshd

RUN sed -i '/imklog/s/^/#/' /etc/rsyslog.conf

RUN mkdir /run/sshd

# Make sure all existinig settings are neutralised....
RUN sed -i 's/^UsePAM .*//g' /etc/ssh/sshd_config 
RUN sed -i 's/^PasswordAuthentication .*//g' /etc/ssh/sshd_config 
RUN sed -i 's/^PubkeyAuthentication .*//g' /etc/ssh/sshd_config 
RUN sed -i 's/^KbdInteractiveAuthentication .*//g' /etc/ssh/sshd_config 
RUN sed -i 's/^PermitRootLogin .*//g' /etc/ssh/sshd_config 
RUN sed -i 's/^ChallengeResponseAuthentication .*//g' /etc/ssh/sshd_config 

# Now set my settings !
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
RUN echo 'UsePAM yes' >> /etc/ssh/sshd_config
RUN echo 'ChallengeResponseAuthentication yes' >> /etc/ssh/sshd_config
RUN echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config 
RUN echo 'KbdInteractiveAuthentication yes' >> /etc/ssh/sshd_config
RUN echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config 
RUN echo 'AuthenticationMethods publickey,keyboard-interactive:pam' >> /etc/ssh/sshd_config 

RUN ssh-keygen -A

RUN groupadd --gid ${GID} workers \
    && useradd --uid ${UID} --gid workers --shell /bin/bash --create-home worker \
    && adduser worker sudo

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/worker/work

COPY sync sync

USER ${UID}

ENTRYPOINT \
    sudo rsyslogd && \
    sudo service ssh restart && \
    pip install -r sync/requirements.txt && \
    python3 sync/app.py && \
    (printf "url=${URL}\ntoken = Bearer ${TOKEN}\nretries = ${RETRIES:-3}\nattribute=${ATTRIBUTE:-uid}\ncache_duration=${CACHE_DURATION:-60}\n" | sudo tee "/etc/pam-weblogin.conf") && \
    sleep infinity
# Watch out for Apple M1 chips
# using the stable branch that doesn't include updates
# using the rolling-release has screwed me before
# use arm64 for Apple M1 chips
# FROM kalilinux/kali-last-release:arm64

# use amd64 for other Apple 
FROM kalilinux/kali-last-release:amd64

# references:
# https://nbctcp.wordpress.com/2017/03/14/installing-discover-on-kali-linux/
# https://www.kali.org/docs/general-use/metapackages/

# set the user as root
USER root

# Set environment variables.
ENV HOME /root

# sometimes Kali changes their GPG key, which makes it really hard to 
# install updates. This will allow it to grab the updates and ignore GPG
# errors, install updates, then install a bunch of dependencies
# more apt metapackages:
# kali-linux-default
# kali-tools-information-gathering
# kali-linux-headless
# forensics-all
# useful CLI interactive GUI for changing Kali settings, installing stuff:
# apt-get install kali-tweaks && kali-tweaks

# adds 6.42 GB of disk space
RUN apt-get -o Acquire::AllowInsecureRepositories=true \
    -o Acquire::AllowDowngradeToInsecureRepositories=true update && \
    apt-get -y upgrade && \
    apt-get update                          && \
    apt-get install -y --no-install-recommends \
    git locate whois curl libxml2-utils virtualenv dnstwist dnsutils \
    iputils-ping recon-ng xml-twig-tools bsdmainutils pip iproute2 python3-pip\
    net-tools sed wget grep coreutils openssl && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

    #  libtool ansible awscli bloodhound feroxbuster gobuster \
    # nishang  build-essential apt-utils cmake libfontconfig1 \
    # libglu1-mesa-dev libgtest-dev libspdlog-dev libboost-all-dev \
    # libncurses5-dev libgdbm-dev libssl-dev libreadline-dev libffi-dev \
    # libsqlite3-dev libbz2-dev mesa-common-dev qtbase5-dev qtchooser qt5-qmake \
    # qtbase5-dev-tools libqt5websockets5 libqt5websockets5-dev \
    # qtdeclarative5-dev golang-go qtbase5-dev libqt5websockets5-dev \
    # libspdlog-dev python3-dev libboost-all-dev mingw-w64 nasm rustc seclists \
    # xlsx2csv xml-twig-tools xspy imagemagick libxext-dev xutils-dev && \
    # veil - no install candidate
    # vim xz-utils zip screen nmap
    # apt-file apt-transport-https arping autoconf automake build-essential \
    # ca-certificates cmake   ethtool g++ gcc  iftop \
    # imagemagick iperf jq jsonlint  lsb-release lsof make \
    # nfs-client openssl pylint   \
    #  sysstat tar tcpdump tcpflow telnet traceroute tree unzip util-linux \

# install more pip dependencies
RUN pip install --no-cache-dir PyPDF3 pyaes censys

# change to the home directory to download/install discover.sh
# WORKDIR /root

# download the discover.sh github repo
RUN git clone https://github.com/THE-MOLECULAR-MAN/discover /opt/discover/

# set the working directory
# can't do this until after the git repo is cloned into the new directory
WORKDIR /opt/discover

# install discover.sh's dependencies
# non-interactive, but takes a while to clone a LOT of repos into /opt
# takes 426 seconds to run
# adds 1.72 GB of disk space
RUN ./update.sh

# copy over a script of commands to pre-cache updates for recon-ng
# which is used heavily by discover.sh
COPY recon-ng-install-all-marketplace-plugins.rec /usr/share/recon-ng/recon-ng-install-all-marketplace-plugins.rec

# run it to prefetch a few minutes worth of stuff that needs to be installed.
# https://github.com/lanmaster53/recon-ng/wiki/Features#automation
# takes about 30 seconds to run
RUN recon-ng -r /usr/share/recon-ng/recon-ng-install-all-marketplace-plugins.rec

# load pre-reqs for theHarvester, run a test w/ it
# https://github.com/laramies/theHarvester/issues/393
# adds 50 MB of disk
WORKDIR /opt/theHarvester
RUN pip install --no-cache-dir -r requirements/base.txt && \
    ./theHarvester.py -b all -l 50 -d example.org -f "test"

# create some necessary directories and
# create symbolic links, otherwise theHarvester throws a LOT of errors
RUN mkdir -p /etc/theHarvester/ /usr/local/etc/theHarvester/ && \
    ln -s /opt/theHarvester/proxies.yaml /etc/theHarvester/proxies.yaml && \
    ln -s /opt/theHarvester/proxies.yaml /usr/local/etc/theHarvester/proxies.yaml

# hadolint recommendation since I'm using a pipe command in the next RUN
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# # define the DISPLAY env variable, fixes a bunch of discover.sh methods
# # that refuse to run
# RUN echo "export DISPLAY=\"hostname:D.S\"" | tee --append \
#     /etc/profile \
#     /root/.profile \
#     /root/.zshrc \
#     /root/.bashrc

# set the working directory for any users that login
WORKDIR /opt/discover

COPY entry-point.sh /app/entry-point.sh
ENTRYPOINT ["/bin/bash", "/app/entry-point.sh"]

FROM ubuntu:14.04
MAINTAINER Jan Keromnes "janx@linux.com"

# Install Firefox build dependencies.
# Packages after "mercurial" are from https://dxr.mozilla.org/mozilla-central/source/python/mozboot/mozboot/debian.py
RUN apt-get update -q && apt-get upgrade -qy && apt-get install -qy clang gdb git mercurial autoconf2.13 build-essential ccache python-dev python-pip python-setuptools unzip uuid zip libasound2-dev libcurl4-openssl-dev libdbus-1-dev libdbus-glib-1-dev libgconf2-dev libgtk2.0-dev libgtk-3-dev libiw-dev libnotify-dev libpulse-dev libxt-dev mesa-common-dev python-dbus yasm xvfb
ENV CC clang
ENV CXX clang++
ENV SHELL /bin/bash

# Install Node.js and npm.
RUN git clone https://github.com/nodejs/node /tmp/node \
 && cd /tmp/node \
 && git checkout v5.6.0 \
 && ./configure \
 && make -j18 \
 && make install \
 && rm -rf /tmp/node

# Install ESLint for Firefox.
# Based on https://dxr.mozilla.org/mozilla-central/source/python/mach_commands.py#222
RUN npm install -g eslint@1.10.3 eslint-plugin-html eslint-plugin-mozilla eslint-plugin-react

# Don't be root.
RUN useradd -m user
USER user
ENV HOME /home/user
WORKDIR /home/user

# Install Mozilla's moz-git-tools.
ENV MOZ_GIT_TOOLS /home/user/moz-git-tools
RUN git clone https://github.com/mozilla/moz-git-tools $MOZ_GIT_TOOLS \
 && cd $MOZ_GIT_TOOLS \
 && git submodule init \
 && git submodule update
ENV PATH $PATH:$MOZ_GIT_TOOLS
RUN echo "\n# Add Mozilla's moz-git-tools to the PATH." >> .bashrc \
 && echo "export PATH=\"\$PATH:$MOZ_GIT_TOOLS\"" >> .bashrc

# Download Firefox's source code.
RUN git clone https://github.com/mozilla/gecko-dev firefox
#RUN hg clone https://hg.mozilla.org/mozilla-central/ firefox
WORKDIR firefox

# Add mozconfig file.
RUN echo "# Firefox build options." >> mozconfig \
 && echo "ac_add_options --enable-application=browser" >> mozconfig \
 && echo "ac_add_options --disable-crashreporter" >> mozconfig \
 && echo "ac_add_options --with-ccache" >> mozconfig \
 && echo "mk_add_options AUTOCLOBBER=1" >> mozconfig \
 && echo "" >> mozconfig \
 && echo "# Building with clang is faster." >> mozconfig \
 && echo "export CC=clang" >> mozconfig \
 && echo "export CXX=clang++" >> mozconfig

# Build Firefox.
RUN ./mach build
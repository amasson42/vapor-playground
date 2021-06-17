FROM swift:5.3-focal

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /package

COPY ./Package.* ./
RUN swift package resolve

COPY . ./

RUN swift build --enable-test-discovery

CMD ["swift", "test", "--enable-test-discovery"]

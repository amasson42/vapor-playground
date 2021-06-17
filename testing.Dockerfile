FROM swift:5.3

WORKDIR /package

COPY ./Package.* ./
RUN swift package resolve

COPY . ./


CMD ["swift", "test", "--enable-test-discovery"]

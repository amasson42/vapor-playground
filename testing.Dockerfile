# ================================
# Testing image
# ================================
FROM swift:5.4-focal

# Install OS updates and, if needed, sqlite3
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install libsqlite3-dev -y \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /testing

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY ./Package.* ./
RUN swift package resolve

# Copy entire repo into container
COPY . .

# Build app and tests before the command execution
RUN swift build --build-tests

# Start the package tests when the image runs
CMD ["swift", "test"]

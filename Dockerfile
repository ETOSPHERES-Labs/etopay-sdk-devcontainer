ARG VARIANT="bookworm"
FROM mcr.microsoft.com/vscode/devcontainers/rust:1-${VARIANT} AS builder

# Install cargo tools
RUN curl -L "https://github.com/cargo-bins/cargo-binstall/releases/latest/download/cargo-binstall-x86_64-unknown-linux-musl.tgz" | tar -xz -C /usr/local/cargo/bin

RUN cargo binstall --no-confirm \
    cargo-audit \
    cargo-nextest \
    cargo-llvm-cov \
    cargo-ndk@3.5.4 \
    cargo-machete \
    sccache \
    wasm-pack@0.13.1 \
    grcov

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash 


# Install grpcurl for Linux (x86_64)
ARG GRPCURL_VERSION="1.9.2"
RUN curl -LO "https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VERSION}/grpcurl_${GRPCURL_VERSION}_linux_x86_64.tar.gz" \
    && tar -xzf grpcurl_${GRPCURL_VERSION}_linux_x86_64.tar.gz \
    && chmod +x grpcurl \
    && mv grpcurl /usr/local/bin/ \
    && rm grpcurl_${GRPCURL_VERSION}_linux_x86_64.tar.gz

# Change to FROM base as devcontainer, if android toolchain is not necessary
FROM mcr.microsoft.com/devcontainers/base:${VARIANT} AS base

# Metadata
LABEL maintainer="ETOSPHERES Labs GmbH : Team Lobster <lobster@etospheres.com>"
LABEL description="Dev container for ETOPay SDK development with tooling"

# Copy only necessary files from the builder stage
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/cargo /home/vscode/.cargo
COPY --from=builder /usr/local/rustup /home/vscode/.rustup
COPY --from=builder /root/.bun/bin/bun /usr/local/bin

# Create symlinks 
RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx

# Add docker client
COPY --from=docker:latest /usr/local/bin/docker /usr/local/bin/

# Set user permissions
RUN chown -R vscode:vscode /home/vscode/.cargo

# install nodejs for the version we want
# See: https://nodejs.org/en/download/package-manager/all#debian-and-ubuntu-based-linux-distributions
# and: https://github.com/nodesource/distributions
RUN curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh \
    && sudo -E bash nodesource_setup.sh \
    && sudo apt -y install --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && rm nodesource_setup.sh

# Install runtime dependencies
ARG CLANG_VERSION="19"
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    libc6 libssl-dev musl-tools clang-${CLANG_VERSION} lld-${CLANG_VERSION} \
    pkg-config  protobuf-compiler libprotobuf-dev \
    gawk bison python3.11-venv \
    && rm -rf /var/lib/apt/lists/*

# Static linking for C++ code
RUN ln -s "/usr/bin/g++" "/usr/bin/musl-g++"

# Set default user
USER vscode

# Configure PATH
ENV CARGO_HOME="/home/vscode/.cargo"
ENV RUSTUP_HOME="/home/vscode/.rustup"
ENV PATH="/usr/local/bin:/home/vscode/.cargo/bin:/home/vscode/.cargo/bin:/home/vscode/.bun/bin:${PATH}"

# Install Rust targets and components
RUN rustup default stable \
    && rustup component add rustfmt clippy llvm-tools-preview \
    && rustup target add x86_64-unknown-linux-musl wasm32-unknown-unknown 

# Clean cargo home to reduce size
RUN rm -rf /usr/local/cargo/registry/*    

# Install JavaScript tools
RUN bun install -g npm ts-node typescript pnpm

RUN mkdir -p /home/vscode/.dapr
RUN touch /home/vscode/.dapr/completion.bash.inc

# Set entrypoint
CMD ["/bin/bash"]

### Swift
FROM base AS swift

# Targets for Apple
RUN rustup target add aarch64-apple-darwin x86_64-apple-darwin aarch64-apple-ios x86_64-apple-ios

USER root

# Install runtime dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    python3 libpython3-dev libz3-dev libncurses-dev \
    && rm -rf /var/lib/apt/lists/*

### Install swift
ARG SWIFT_VERSION="swift-6.0.3"

# Install required dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    binutils-gold gcc git libcurl4-openssl-dev libedit-dev libicu-dev libncurses-dev libpython3-dev libsqlite3-dev libxml2-dev pkg-config tzdata uuid-dev \
    && rm -rf /var/lib/apt/lists/*

# Install via tar (and check signature)
RUN curl -L "https://download.swift.org/${SWIFT_VERSION}-release/debian12/${SWIFT_VERSION}-RELEASE/${SWIFT_VERSION}-RELEASE-debian12.tar.gz" -o swift.tar.gz \
    && curl -L "https://download.swift.org/${SWIFT_VERSION}-release/debian12/${SWIFT_VERSION}-RELEASE/${SWIFT_VERSION}-RELEASE-debian12.tar.gz.sig" -o swift.tar.gz.sig \
    && wget -q -O - https://swift.org/keys/release-key-swift-6.x.asc | gpg --import - \
    && gpg --verify swift.tar.gz.sig \
    && tar -xzf swift.tar.gz \
    && mv ${SWIFT_VERSION}-RELEASE-debian12 /usr/share/swift \
    && rm swift.tar.gz swift.tar.gz.sig
# add to path
ENV PATH="/usr/share/swift/usr/bin:${PATH}"

RUN rustup default stable \
    && rustup component add rustfmt clippy llvm-tools-preview \
    && rustup target add x86_64-unknown-linux-musl wasm32-unknown-unknown 

### Android
FROM swift AS android

# Targets for Android
RUN rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android

USER root

### Install JDK from Oracle (v23 is not available from openjdk on debian bookworm)
ARG JAVA_VERSION="23.0.2"
ARG JAVA_DOWNLOAD_URL="23.0.2"
RUN curl -L https://download.java.net/java/GA/jdk23.0.2/6da2a6609d6e406f85c491fcb119101b/7/GPL/openjdk-23.0.2_linux-x64_bin.tar.gz -o openjdk.tar.gz \
    && tar -xzf openjdk.tar.gz \
    && mv jdk-23.0.2 /usr/share/openjdk \
    && rm openjdk.tar.gz
# add to path
ENV PATH="/usr/share/openjdk/bin:${PATH}"

ENV GRADLE_ROOT=/home/dev/opt/gradle
RUN mkdir -p ${GRADLE_ROOT}
ARG GRADLE_VERISON="8.13"
ARG GRADLE_SHA="20f1b1176237254a6fc204d8434196fa11a4cfb387567519c61556e8710aed78"
RUN wget https://services.gradle.org/distributions/gradle-${GRADLE_VERISON}-bin.zip -O gradle-${GRADLE_VERISON}-bin.zip \
    && sha256sum gradle-${GRADLE_VERISON}-bin.zip \
    && echo "${GRADLE_SHA}  gradle-${GRADLE_VERISON}-bin.zip" | sha256sum -c - \
    && unzip gradle-${GRADLE_VERISON}-bin.zip -d ${GRADLE_ROOT} \
    && rm gradle-${GRADLE_VERISON}-bin.zip
ENV PATH=${PATH}:${GRADLE_ROOT}/gradle-${GRADLE_VERISON}/bin

# Set the ${ANDROID_HOME} variable, so that the tools can find our installation.
# See https://developer.android.com/studio/command-line/variables#envar.
ENV ANDROID_HOME=/home/dev/opt/android-sdk

# Download and extract the command-line tools into ${ANDROID_HOME}.
RUN mkdir -p ${ANDROID_HOME}
ARG COMMANDLINETOOLS_VERSION="11076708"
ARG COMMANDLINETOOLS_SHA="2d2d50857e4eb553af5a6dc3ad507a17adf43d115264b1afc116f95c92e5e258"
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-${COMMANDLINETOOLS_VERSION}_latest.zip \
    -O ${HOME}/commandlinetools-linux-${COMMANDLINETOOLS_VERSION}_latest.zip \
    && sha256sum ${HOME}/commandlinetools-linux-${COMMANDLINETOOLS_VERSION}_latest.zip \
    && echo "${COMMANDLINETOOLS_SHA} $HOME/commandlinetools-linux-${COMMANDLINETOOLS_VERSION}_latest.zip" | sha256sum -c - \
    && unzip ${HOME}/commandlinetools-linux-${COMMANDLINETOOLS_VERSION}_latest.zip -d ${ANDROID_HOME}/cmdline-tools \
    && rm ${HOME}/commandlinetools-linux-${COMMANDLINETOOLS_VERSION}_latest.zip

# Add the relevant directories to the $PATH.
ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/cmdline-tools/bin:${ANDROID_HOME}/platform-tools

ARG NDK_VERSION="26.2.11394342"
RUN yes | sdkmanager --licenses \
    && sdkmanager --verbose \
    "build-tools;34.0.0" \
    "ndk;${NDK_VERSION}" \
    "platforms;android-33" \
    # "system-images;android-29;default;x86_64" \
    && rm -R ${HOME}/.android/

ENV ANDROID_NDK_HOME=${ANDROID_HOME}/ndk/${NDK_VERSION}

RUN cd ${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/ \
    && ln -s aarch64-linux-android30-clang aarch64-linux-android-clang

ENV PATH=${PATH}:${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin


## Devcontainer
FROM android AS devcontainer

# Set default user
USER root

# Set entrypoint
CMD ["/bin/bash"]

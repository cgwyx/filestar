# build container stage
FROM golang:latest AS build-env
#FROM golang:1.14.7-buster AS build-env
#FROM golang:1.14.2 AS build-env
WORKDIR /root
# branch or tag of the lotus version to build
ARG BRANCH=v1.2.2
#ARG BRANCH=interopnet
# ARG BRANCH=v0.10.2

#RUN echo "Building lotus from branch $BRANCH"
########
RUN  apt-get update && \
     apt-get install mesa-opencl-icd ocl-icd-opencl-dev gcc git bzr jq pkg-config curl libclang-dev -y && \
     apt-get upgrade

#RUN apt-get update -y && \
    #apt-get install sudo curl git mesa-opencl-icd ocl-icd-opencl-dev gcc git bzr jq pkg-config -y
#RUN apt update -y && \
    #apt install gcc git bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev llvm clang opencl-headers wget -y
    #apt upgrade -y
#RUN go env -w GOPROXY=https://goproxy.cn

RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y

ENV PATH=/root/.cargo/bin:$PATH

#RUN curl -sSf https://sh.rustup.rs | sh -s -- -y
#RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
#RUN echo "export PATH=~/.cargo/bin:$PATH" >> ~/.bashrc
#######

WORKDIR /

RUN git clone -b $BRANCH https://github.com/filestar-project/lotus.git --recursive && \
    cd lotus && \
    export RUSTFLAGS="-C target-cpu=native -g" && \
    export FFI_BUILD_FROM_SOURCE=1 && \
    make all && \
    make install


# runtime container stage
FROM nvidia/opencl:devel-ubuntu18.04
#FROM nvidia/opencl:runtime-ubuntu18.04
#FROM nvidia/cudagl:10.2-devel-ubuntu18.04
#FROM apicciau/opencl_ubuntu:latest

# Instead of running apt-get just copy the certs and binaries that keeps the runtime image nice and small
#RUN apt-get update -y && \
    #apt-get install sudo ca-certificates mesa-opencl-icd ocl-icd-opencl-dev clinfo -y && \
    #rm -rf /var/lib/apt/lists/*
RUN apt-get update -y && \
    apt-get install clinfo -y
    
COPY --from=build-env /lotus /lotus
COPY --from=build-env /etc/ssl/certs /etc/ssl/certs
#COPY LOTUS_VERSION /VERSION

COPY --from=build-env /lib/x86_64-linux-gnu/libdl.so.2 /lib/libdl.so.2
COPY --from=build-env /lib/x86_64-linux-gnu/libutil.so.1 /lib/libutil.so.1 
COPY --from=build-env /usr/lib/x86_64-linux-gnu/libOpenCL.so.1.0.0 /lib/libOpenCL.so.1
COPY --from=build-env /lib/x86_64-linux-gnu/librt.so.1 /lib/librt.so.1
COPY --from=build-env /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/libgcc_s.so.1

#COPY config/config.toml /root/config.toml
#COPY scripts/entrypoint /bin/entrypoint

RUN ln -s /lotus/lotus /usr/bin/lotus && \
    ln -s /lotus/lotus-miner /usr/bin/lotus-miner && \
    ln -s /lotus/lotus-worker /usr/bin/lotus-worker

VOLUME ["/root","/var"]


# API port
EXPOSE 1234/tcp

# API port
EXPOSE 2345/tcp

# API port
EXPOSE 3456/tcp

# P2P port
EXPOSE 1347/tcp

# ipfs port
EXPOSE 4567/tcp

ENV IPFS_GATEWAY=https://filestar-proofs.s3.cn-east-1.jdcloud-oss.com/ipfs/
# export IPFS_GATEWAY=https://filestar-proofs.s3.cn-east-1.jdcloud-oss.com/ipfs/

ENV FIL_PROOFS_MAXIMIZE_CACHING=1

ENV FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1

ENV FIL_PROOFS_USE_GPU_TREE_BUILDER=1


WORKDIR /lotus


CMD ["lotus", "daemon", "&"]
#ENTRYPOINT ["/bin/entrypoint"]
#CMD ["-d"]


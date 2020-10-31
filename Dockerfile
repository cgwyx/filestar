FROM nvidia/opencl:devel-ubuntu18.04
#FROM nvidia/opencl:runtime-ubuntu18.04
#FROM nvidia/cudagl:10.2-devel-ubuntu18.04
#FROM apicciau/opencl_ubuntu:latest


RUN apt update -y &&\
    apt install mesa-opencl-icd ocl-icd-opencl-dev gcc git bzr jq pkg-config curl libclang-dev -y &&\
    apt upgrade -y


RUN add-apt-repository ppa:longsleep/golang-backports -y &&\
    apt update -y &&\
    apt-get install golang-go -y

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &&\

RUN git clone https://github.com/filestar-project/lotus.git &&\
    cd lotus &&\
    export RUSTFLAGS="-C target-cpu=native -g" &&\
    export FFI_BUILD_FROM_SOURCE=1 &&\
    make all &&\
    sudo make install

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


ENV IPFS_GATEWAY=https://proof-parameters.s3.cn-south-1.jdcloud-oss.com/ipfs/

ENV FIL_PROOFS_MAXIMIZE_CACHING=1

ENV FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1

ENV FIL_PROOFS_USE_GPU_TREE_BUILDER=1


WORKDIR /lotus


CMD ["lotus", "daemon", "&"]
#ENTRYPOINT ["/bin/entrypoint"]
#CMD ["-d"]


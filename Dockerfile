FROM python:3.9.16-bullseye
LABEL maintainer="Erik Ferlanti <eferlanti@tacc.utexas.edu>"

# adding pre-reqs
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    cmake \
    gdb \
    hdf5-tools \ 
    h5utils \ 
    libhdf5-dev \
    libhdf5-103 \
    libhdf5-103-1 \
    libhdf5-cpp-103 \
    libhdf5-cpp-103-1 \
    liblz4-dev \
    lz4 \
    vim-tiny && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /code

# build ImarisWriter libraries
RUN git clone https://github.com/imaris/ImarisWriter.git && \
    cd ImarisWriter && \
    mkdir release && \
    cd release && \
    cmake .. && \
    make && make install && \
    cp include/* /usr/local/include && \
    cp lib/* /usr/local/lib && \
    ldconfig

WORKDIR /code

# build ImarisWriter python libraries
RUN cd ImarisWriter/python/PyImarisWriter && \
    mkdir -p /usr/local/lib/python3.9/site-packages/PyImarisWriter && \
    cp __init__.py PyImarisWriter.py ImarisWriterCtypes.py /usr/local/lib/python3.9/site-packages/PyImarisWriter

WORKDIR /code

# build ImarisWriterTest programs
RUN git clone https://github.com/imaris/ImarisWriterTest.git && \
    cd ImarisWriterTest/application && \
    g++ -I. -I/code -L/code/ImarisWriter/release/lib -o ImarisWriterTestRelease ImarisWriterTest.cxx -lbpImarisWriter96 -lpthread && \
    cd ../testC && \
    gcc -I/code -L/code/ImarisWriter/release/lib -o bpImarisWriter96TestProgram bpImarisWriter96TestProgram.c -lbpImarisWriter96 -lpthread

# install python libraries
RUN pip install numpy

# put test programs in PATH
RUN ln -s /code/ImarisWriterTest/application/ImarisWriterTestRelease /usr/local/bin/. && \
    ln -s /code/ImarisWriterTest/testC/bpImarisWriter96TestProgram /usr/local/bin/.


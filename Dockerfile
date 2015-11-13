FROM kavolorn/arm-opencv:3.0.0

MAINTAINER Alexey Kornilov <alexey.kornilov@kavolorn.ru>

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y gcc g++ libicu52

RUN cd && wget -O boost_1_59_0.tar.gz http://sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz/download \
	&& tar -xvf boost_1_59_0.tar.gz && rm boost_1_59_0.tar.gz \
	&& cd boost_1_59_0 \
	&& ./bootstrap.sh --with-libraries=python,thread --with-python=python3.4 --with-icu=/usr/lib/arm-linux-gnueabihf/ \
	&& ./b2 -j2 && ./b2 install \
	&& cd && rm -rf boost_1_59*

RUN apt-get install -y libprotobuf-dev libleveldb-dev \
	libsnappy-dev libhdf5-serial-dev protobuf-compiler \
	libatlas-base-dev libgflags-dev libgoogle-glog-dev liblmdb-dev

RUN cd && git clone https://github.com/BVLC/caffe \

	# Preparing known working commit 
	&& cd caffe && git reset --hard f1cc905d4d75570b71677faaaee11062ff94fdaa \
	&& mkdir build && cd build \

	# Fixing python detector
	&& sed -i -- 's/python-py/python/' ../cmake/Dependencies.cmake \
	&& sed -i -- 's/PYTHON-PY/PYTHON/' ../cmake/Dependencies.cmake \
	
	&& cmake -DCPU_ONLY=ON -DCMAKE_INSTALL_PREFIX=/usr/local/caffe \
		-DPython_ADDITIONAL_VERSIONS=3.4 -Dpython_version=3.4 .. \
	&& make -j2 \

	# Installing dependencies for pytest
	&& apt-get install -y python3-pip python3-scipy python3-skimage \
	&& pip3 install google \
	&& pip3 install protobuf \
	&& 2to3-3.4 -w /usr/local/lib/python3.4/dist-packages/google/protobuf/ \

	# Testing and installing
	&& make pytest && make install \
	&& cd && rm -rf caffe

ENV PATH /usr/local/caffe/bin:$PATH
ENV PYTHONPATH /usr/local/caffe/python
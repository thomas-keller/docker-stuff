FROM nvidia/cuda:7.5-cudnn4-devel

MAINTAINER Thomas Keller <thomas.e.keller@gmail.com>


#Kudos to neuralniche/ grahama
# https://hub.docker.com/r/grahama/tf/
# these dependencies are based off his almost 100%
# Pick up some TF dependencies
#note: need to git clone the tensorflow library and cd into the tools/docker directory before starting the docker build
RUN apt-get update && apt-get install -y \
        software-properties-common \
        build-essential \ 
        git \
        pkg-config \ 
        bc \
        curl \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        python3-numpy \
        python3-scipy \
        python3 \
        python3-dev \
        pkg-config \
        swig \
        zip \
        zlib1g-dev \
        libhdf5-dev \
        libyaml-dev \
        libjpeg-dev \
        gfortran \
        libopenblas-dev \
        liblapack-dev \
        libhdf5-dev \
        libjpeg-dev \
        vim \
        unzip \
        cmake \
        libatlas-base-dev \
        libjasper-dev \
        libgtk2.0-dev \
        libavcodec-dev \
        libavformat-dev \
        libswscale-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libjasper-dev \
        libv4l-dev 
        
    #apt-get clean 
    #rm -rf /var/lib/apt/lists/*
    
RUN add-apt-repository -y ppa:openjdk-r/ppa && \
    apt-get update && apt-get install -y --force-yes openjdk-8-jdk openjdk-8-jre-headless && \
    apt-get clean
    #rm -rf /var/lib/apt/lists/*    

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

#If you want additional python3 packages ADD THEM HERE
RUN pip3 install --pre \
        ipykernel \
        jupyter \
        matplotlib \
        seaborn \
        pandas \
        cython \
        statsmodels \
        scikit-learn \
        asciitree \        
        && \
    pip3 install --pre --upgrade git+git://github.com/fchollet/keras.git@master && \
    python3.5 -m ipykernel.kernelspec


    # messes up apt installs later
    # rm -rf /var/lib/apt/lists/*
RUN mkdir ~/.keras/ && echo '{"epsilon": 1e-07, "floatx": "float32", "backend": "tensorflow"}' > ~/.keras/keras.json

#####
#make OpenCV (kind of a pain)
RUN git clone https://github.com/Itseez/opencv.git && \
    cd opencv && mkdir cv_bin && cd cv_bin && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j4 && make install
     

#######
# Build from Source with Bazel
RUN echo "startup --batch" >>/root/.bazelrc

RUN echo "build --spawn_strategy=standalone --genrule_strategy=standalone" \
    >>/root/.bazelrc

ENV BAZELRC /root/.bazelrc
ENV BAZEL_VERSION 0.2.0

#dying because of "no such package '@jpeg_archive//" why???
#worked before with grahama
WORKDIR /
RUN mkdir /bazel && \
    cd /bazel && \
    curl -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    curl -fSsL -o /bazel/LICENSE.txt https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE.txt && \
    chmod +x bazel-*.sh && \
    ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    cd / && \
    rm -f /bazel/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh

# Download and build TensorFlow.
RUN git clone --recursive https://github.com/tensorflow/tensorflow.git && \
    cd tensorflow && \
    # using master instead of r0.7
    git checkout master

WORKDIR /tensorflow
##### Configure the build for our CUDA configuration.

# # need for ./configure to run without input
ENV CUDA_TOOLKIT_PATH /usr/local/cuda-7.5
ENV CUDNN_INSTALL_PATH /usr/lib/x86_64-linux-gnu
ENV TF_NEED_CUDA 1
ENV PYTHON_BIN_PATH /usr/bin/python3
ENV TF_CUDA_COMPUTE_CAPABILITIES "3.0"
RUN ln -s /usr/include/cudnn.h /usr/lib/x86_64-linux-gnu/cudnn.h

RUN TF_UNOFFICIAL_SETTING=1 ./configure && \
    bazel build -c opt --config=cuda tensorflow/cc:tutorials_example_trainer && \
    bazel build -c opt --config=cuda tensorflow/tools/pip_package:build_pip_package && \
    bazel build -c opt --config=cuda tensorflow/core/distributed_runtime/rpc:grpc_tensorflow_server && \
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
    pip3 install /tmp/tensorflow_pkg/*.whl && \
    rm -rf /tmp/

WORKDIR /root/

## Delete from Build
RUN rm -rf /root/.cache /tensorflow/ /bazel/

# cant remember exactly but need to install after cython installs i believe
RUN pip3 install h5py Pillow


# Set up our notebook config.
COPY jupyter_notebook_config.py /root/.jupyter/

# Copy sample notebooks.
COPY notebooks /notebooks

# Jupyter has issues with being run directly:
#   https://github.com/ipython/ipython/issues/7062
# We just add a little wrapper script.
COPY run_jupyter.sh /

# TensorBoard
EXPOSE 6006
# IPython
EXPOSE 8888

WORKDIR "/notebooks"

CMD ["/run_jupyter.sh"]

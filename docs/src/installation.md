# Installation

`OSRM.jl` is a bit more difficult to install than other Julia packages because of the C++ dependencies.

## Building OSRM

Many people use OSRM through Docker images, but since we are interfacing directly with the routing engine it needs to be installed on the computer we're using. You need to clone the [OSRM git repository](https://github.com/Project-OSRM/osrm-backend) and then compile it. You'll need to have a compilation toolchain on your system, including CMake and a C++ compiler. OSRM requires a number of libraries as well, notably [Boost](https://www.boost.org/) and [oneAPI TBB](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onetbb.html). OSRM is known to work on Linux and Mac, but I have not been able to get it to compile on Windows (you can use Windows Subsystem for Linux to run it, however).

The general process for compiling OSRM is the following:

    cd osrm-backend/
    mkdir build  # create a directory for the build
    cd build
    cmake .. # use CMake to configure the OSRM build process
    cmake --build . -j8 # Build OSRM, using multiple threads (much faster - replace 8 with the number of cores in your system for optimal performance)
    sudo cmake --build . --target install # Install OSRM. Your password may be required.

If you encounter no errors, OSRM is now installed. The most common errors you'll encounter will be related to missing libraries. If you're using a Mac and Homebrew, you can install the needed libraries like this:

    brew install tbb boost@1.76

OSRM is currently not compatible with newer versions of Boost. You may need to explicitly tell OSRM where to find libraries, as well. With tbb and boost installed, this is the `cmake` command I use to configure OSRM prior to building that enables finding all needed libraries (update paths as needed):

    cmake .. -DBOOST_ROOT=/opt/homebrew/opt/boost@1.76 -DTBB_INCLUDE_DIR=/opt/homebrew/Cellar/tbb/2021.9.0/include/

## Installing OSRM.jl

OSRM.jl is not yet available from the General registry. I recommend installing it from Github for now. From the Julia REPL:

    ]add https://github.com/mattwigway/OSRM.jl

## Building the C++ shim

OSRM.jl and uses Julia's ccall functionality to call OSRM. Since OSRM is written in C++, and ccall only works with C functions, OSRM.jl includes a very small C++ shim around OSRM with `extern "C"` functions to initialize, route, and shut down an OSRM routing engine. The code for this is in the `cxx` folder of this repository. This shim is built as a shared library libosrmjl.so (libosrmjl.dylib on Mac, libosrmjl.dll on Windowns) which contains a shim around OSRM, and is built from the code in the `cxx` folder of the OSRM.jl repository.

It is important that the version of the C++ shim match the version of OSRM.jl, or errors will result. I recommend building the shim from the package source code installed in Julia to ensure a match. From the Julia prompt, run

    using OSRM
    pathof(OSRM)

This will print out a path, something like `/Users/{you}/.julia/packages/OSRM/JZIct/src/OSRM.jl`. Remove `src/OSRM.jl` from the end of the path, and navigate to that directory in a terminal, then run the following commands.

    cd cxx
    mkdir build
    cd build
    cmake ..
    cmake --build .
    sudo cmake --build . --target install

This looks very similar to building OSRM. If OSRM was installed correctly, this should install the `libosrmjl` library on your system.


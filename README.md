inVRs Superbuild
================

This project aims at making inVRs and its dependencies easier to download and install on Linux and Windows platforms.

## Status: **Alpha**

This might work for some people some of the time.
If you are not easily intimidated by CMake scripts, you are welcome to try it and provide feedback!


## Building on Windows

### Prerequisites

Make sure you have the following programs installed:

 - CMake (from http://www.cmake.org/download/)
 - git (e.g. from http://msysgit.github.io)
 - Subversion (e.g. from https://sliksvn.com/download/)
 - A working C++ compiler (e.g. Microsoft Visual C++ Express)

To verify a working set of programs, you should be able to run ``cmake``, ``git``, and ``svn`` from a console window:

 1. Open a (developer) console window (e.g. "Developer console window for VS2013")
 2. Verify that the command ``cmake --version`` does not produce an error
 3. Verify that the command ``git --version`` does not produce an error
 4. Verify that the command ``svn --version`` does not produce an error

### Build instructions

 1. Open a developer console window
 2. Set some variable names (adjust as needed) and ensure that the build directory exists:

    ```
    set SOURCEDIR=F:\inVRs-superbuild
    set BUILDDIR=%SOURCEDIR%\build
    mkdir %BUILDDIR%
    ```
    You can of course omit this step and just fill in the appropriate path name in the following steps.
 3. Run CMake:

    ```
    cd %BUILDDIR&
    cmake %SOURCEDIR%
    ```
 4. *Variant A:* Build via CMake:
    
    ```
    cmake --build %BUILDDIR%
    ```
 5. *Variant B:* Build in Visual Studio:
    Open the Visual Studio Solution ``%BUILDDIR%\inVRs-superbuild.sln`` in Microsoft Visual Studio and build it.

## General build notes

### Building without network connection

You will need a network connection the first time you run cmake, so that the ``SUPERBUILD_DOWNLOAD_CACHE_DIRECTORY`` and ``SUPERBUILD_VCS_CACHE_DIRECTORY`` subdirectories can be populated.
Afterwards, you can enable ``SUPERBUILD_DISABLE_VCS_UPDATES`` in your cmake cache, so that the git and subversion update steps are skipped.

### Changing the set of repositories

The repositories that are built by the superbuild are defined in ``repositories/default.repositories.cmake``.
If you want to modify the selected package versions or locations, you can create a file ``repositories/SOMENAME.repositories.cmake``
and select the right value for ``SUPERBUILD_REPOSITORY_COLLECTION`` in the cmake cache.

### CMake cache variables that influence the build

Generally, inVRs-SuperBuild cache variables are prefixed with ``SUPERBUILD_`` so that you can easily distinguish them from other variables.

## Further Information

For more information on inVRs, check out http://inVRs.org

cmake_minimum_required ( VERSION 3.0 FATAL_ERROR )
project ( inVRs-SuperBuild )

include ( ExternalProject )

# windows-builds of boost need different compilation commands:
if ( WIN32 )
	set ( BOOST_BOOTSTRAP_COMMAND ./bootstrap.bat)
	set ( BOOST_B2_COMMAND ./b2.exe install "--prefix=${CMAKE_INSTALL_PREFIX}" )
else()
	set ( BOOST_BOOTSTRAP_COMMAND ./bootstrap.sh "--prefix=${CMAKE_INSTALL_PREFIX}" )
	set ( BOOST_B2_COMMAND ./b2 install )
endif()
# version 1.56 is the latest version recognised by cmake 3.0.2:
ExternalProject_Add(
	Boost
	PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/boost"
	BUILD_IN_SOURCE 1
	URL "http://sourceforge.net/projects/boost/files/boost/1.56.0/boost_1_56_0.tar.bz2/download"
	URL_HASH "MD5=a744cf167b05d72335f27c88115f211d"
	UPDATE_COMMAND "${BOOST_BOOTSTRAP_COMMAND}"
	CONFIGURE_COMMAND ""
	BUILD_COMMAND "${BOOST_B2_COMMAND}"
	)

ExternalProject_Add(
	OpenSG
	PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/opensg"
	GIT_REPOSITORY "git://git.code.sf.net/p/opensg/code"
	)
# -> collada jpeg png freetype
# -> boost

# inVRs:
ExternalProject_Add(
	inVRs
	SVN_REPOSITORY "https://svn.lrz.de/repos/inVRs/branches/inVRs_OSG"
	DEPENDS OpenSG
	)

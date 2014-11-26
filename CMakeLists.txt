cmake_minimum_required( VERSION 3.0 FATAL_ERROR )
project( inVRs-SuperBuild )

include( ExternalProject )

function( tristate_option OPT )
	set( USE_${OPT} auto CACHE STRING 
	"Which ${OPT} should be used? 'force-system' to require an already installed version, 'force-internal' to force building it, 'auto' to try a system-wide installation and fall back to the internal version if none is found." )
	set_property( CACHE USE_${OPT} PROPERTY STRINGS auto force-system force-internal )

	# to simplify find_package statements:
	if( "${USE_${OPT}}" STREQUAL "force-system" )
		set( ${OPT}_REQUIRED "REQUIRED" PARENT_SCOPE )
	endif()
endfunction()

############################################################
### Boost
set( BOOST_REQUIRED_COMPONENTS system filesystem )
tristate_option( Boost )
if ( "${USE_Boost}" STREQUAL "auto" )
	# try already installed version first:
	find_package( Boost COMPONENTS ${BOOST_REQUIRED_COMPONENTS} ${Boost_Required} )
endif()

if( NOT Boost_FOUND )
	# windows-builds of boost need different compilation commands:
	if( WIN32 )
		set( BOOST_BOOTSTRAP_COMMAND ./bootstrap.bat)
		set( BOOST_B2_COMMAND ./b2.exe install )
	else()
		set( BOOST_BOOTSTRAP_COMMAND ./bootstrap.sh "--prefix=${CMAKE_INSTALL_PREFIX}" )
		set( BOOST_B2_COMMAND ./b2 install )
	endif()
	list( APPEND BOOST_B2_COMMAND "--layout=versioned" "--build-type=complete" "--prefix=${CMAKE_INSTALL_PREFIX}" )
	foreach( component IN LISTS BOOST_REQUIRED_COMPONENTS )
		list( APPEND BOOST_B2_COMMAND "--with-${component}" )
	endforeach()
	# version 1.56 is the latest version recognised by cmake 3.0.2:
	ExternalProject_Add(
		Boost
		PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/boost"
		BUILD_IN_SOURCE 1
		DOWNLOAD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/download"
		URL "http://sourceforge.net/projects/boost/files/boost/1.56.0/boost_1_56_0.tar.bz2/download"
		URL_HASH "MD5=a744cf167b05d72335f27c88115f211d"
		UPDATE_COMMAND "${BOOST_BOOTSTRAP_COMMAND}"
		CONFIGURE_COMMAND ""
		BUILD_COMMAND ""
		INSTALL_COMMAND "${BOOST_B2_COMMAND}"
		)
endif()

############################################################
### OpenSG
ExternalProject_Add(
	OpenSG
	PREFIX "${CMAKE_CURRENT_BINARY_DIR}/external/opensg"
	GIT_REPOSITORY "git://git.code.sf.net/p/opensg/code"
	)
# -> collada jpeg png freetype
# -> boost

############################################################
### inVRs
ExternalProject_Add(
	inVRs
	SVN_REPOSITORY "https://svn.lrz.de/repos/inVRs/branches/inVRs_OSG"
	DEPENDS OpenSG
	)

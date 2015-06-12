## project download locations for each ExternalProject:

# version 1.56 is the latest version recognised by cmake 3.0.2:
set( Boost_DOWNLOAD
	URL "http://sourceforge.net/projects/boost/files/boost/1.56.0/boost_1_56_0.tar.bz2/download"
	URL_HASH "MD5=a744cf167b05d72335f27c88115f211d"
	)

set( FreeGLUT_DOWNLOAD
	URL "http://downloads.sourceforge.net/project/freeglut/freeglut/3.0.0%20Release%20Candidate%201/freeglut-3.0.0-rc1.tar.gz"
	URL_HASH "MD5=9679f19e5d9fd211c904698be0cfec2b"
	)

# Homepage: http://glew.sourceforge.net/
set( GLEW_DOWNLOAD
	URL "http://downloads.sourceforge.net/project/glew/glew/1.11.0/glew-1.11.0.zip"
	URL_HASH "MD5=a36ecf091ae4887fb980ca943c75b1ce"
	)

set( inVRs_DOWNLOAD
	SVN_REPOSITORY "https://svn.lrz.de/repos/inVRs/branches/inVRs_OSG"
	)

set( OpenSG_DOWNLOAD
	GIT_REPOSITORY "git://git.code.sf.net/p/opensg/code"
	)

set( PNG_DOWNLOAD
	URL "http://download.sourceforge.net/libpng/libpng-1.6.15.tar.gz"
	URL_HASH "MD5=829a256f3de9307731d4f52dc071916d"
	)

set( SUPERBUILD_ENABLE_PCRE OFF CACHE FORCE "Disabled by repository collection setup." )
set( SUPERBUILD_ENABLE_QT OFF CACHE FORCE "Disabled by repository collection setup." )
set( SUPERBUILD_ENABLE_ZLIB OFF CACHE FORCE "Disabled by repository collection setup." )

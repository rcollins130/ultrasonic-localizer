while getopts "t:" flag; do
    case "${flag}" in
        t )
			TOOLCHAIN_FILE=$OPTARG
			shift
			;;
    esac
	shift
done

if [ $# -gt 1 ]; then
	BUILD_TYPE=$1
	GENERATOR=$2
else
	echo "usage: $0 [-t toolchain_file_path] <build_type> <generator>

	toolchain_file_path: specify the path to a toolchain file for cross compiling
	build_type: one of Debug, RelWithDebInfo, Release, or MinSizeRel (or possibly other custom types)
	generator: the generator to pass to CMake, e.g., \"MinGW Makefiles\". cmake --help for list of generators"
	exit
fi

if [ "$TOOLCHAIN_FILE" = "" ]; then
	CMAKE_TOOLCHAIN_OPT=""
else
	CMAKE_TOOLCHAIN_OPT="-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE"
fi

mkdir -p "build-$BUILD_TYPE"
cd "build-$BUILD_TYPE"
cmake -G "$GENERATOR" $CMAKE_TOOLCHAIN_OPT -DCMAKE_BUILD_TYPE="$BUILD_TYPE" ..

# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]
# See env_vars.sh for extra environment variables

function build_wheel {
    if [ -z "$IS_OSX" ]; then
        yum update -y;
        yum install libffi-devel -y
        pip install pytest pycparser
        # Work round build dependencies spec in pyproject.toml
        build_bdist_wheel $@
    else
        export FFLAGS="$FFLAGS -fPIC"
        build_osx_wheel $@
    fi
}

function set_arch {
    local arch=$1
    export CC="clang $arch"
    export CXX="clang++ $arch"
    export CFLAGS="$arch"
    export FFLAGS="$arch"
    export FARCH="$arch"
    export LDFLAGS="$arch"
}


function build_osx_wheel {
    # Build 64-bit wheel
    # Standard gfortran won't build dual arch objects.
    local repo_dir=${1:-$REPO_DIR}
    local py_ld_flags="-Wall -undefined dynamic_lookup -bundle"

    install_gfortran
    # 64-bit wheel
    local arch="-m64"
    set_arch $arch
    build_libs x86_64
    # Build wheel
    export LDSHARED="$CC $py_ld_flags"
    export LDFLAGS="$arch $py_ld_flags"
    # Work round build dependencies spec in pyproject.toml
    # See e.g.
    # https://travis-ci.org/matthew-brett/scipy-wheels/jobs/387794282
    build_wheel_cmd "build_wheel_with_patch" "$repo_dir"
}

#function run_tests {
#    # Runs tests on installed distribution from an empty directory
#    python --version
#    python -c 'import sys; import yourpackage; sys.exit(yourpackage.test())'
#}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    # OSX tests seem to time out pretty often
    if [ -z "$IS_OSX" ]; then
        local testmode="full"
    else
        local testmode="fast"
    fi
    py.test ../c/ ../testing/

    ## Check bundled license file
    #python ../check_installed_package.py
    ## Run tests
    #python ../run_scipy_tests.py $testmode -- -n8 -rfEX
    ## Show BLAS / LAPACK used
    #python -c 'import scipy; scipy.show_config()'
}

function install_run {
    # Override multibuild test running command, to preinstall packages
    # that have to be installed before TEST_DEPENDS.
    pip install $(pip_opts) setuptools_scm

    # Copypaste from multibuild/common_utils.sh:install_run
    install_wheel
    mkdir tmp_for_test
    (cd tmp_for_test && run_tests)
}

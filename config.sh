# Override few multibuild functions to customize behavior

function build_wheel {
    yum update -y;
    yum install libffi-devel -y
    pip install pytest pycparser
    build_bdist_wheel $@
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    py.test ../cffi/c/ ../cffi/testing/
}

function install_run {
    # Copypaste from multibuild/common_utils.sh:install_run
    install_wheel
    mkdir tmp_for_test
    (cd tmp_for_test && run_tests)
}

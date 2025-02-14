function ci_codelabs () {
    local channel="$1"
    shift

    # plugin_codelab is a special case since it's a plugin.  Analysis doesn't seem to be working.
    pushd $PWD
    echo "== TESTING plugin_codelab on $channel"
    cd ./plugin_codelab
    dart format --output none --set-exit-if-changed .;
    popd

    # Grab packages.
    for dir in `find . -name pubspec.yaml -exec dirname {} \;`; do
      pushd $dir
      flutter pub get
      popd
    done

    local arr=("$@")
    for CODELAB in "${arr[@]}"
    do
        echo "== Testing '${CODELAB}' on $channel"
        declare -a PROJECT_PATHS=($(
        find $CODELAB -not -path './flutter/*' -not -path './plugin_codelab/pubspec.yaml' -name pubspec.yaml -exec dirname {} \;
        ))
        for PROJECT in "${PROJECT_PATHS[@]}"
        do
            pushd "${PROJECT}"
            echo "== Testing '${PROJECT}'"

            # Run the analyzer to find any static analysis issues.
            if [ "$channel" == 'stable' ]; then
              dart analyze --fatal-infos
            else
              dart analyze
            fi

            # Run the formatter on all the dart files to make sure everything's linted.
            dart format --output none --set-exit-if-changed .

            # Run the actual tests.
            if [ -d "test" ]
            then
                flutter test
            fi

            popd
        done
    done

    declare -a WORKSHOP_STEP_PATHS=($(
        find dartpad_codelabs -name snippet.dart -exec dirname {} \; 
      ))

    for WORKSHOP_STEP_PATH in "${WORKSHOP_STEP_PATHS[@]}"; do
      echo "== TESTING $WORKSHOP_STEP_PATH"
      (
        cd "$WORKSHOP_STEP_PATH"
        if [[ -r solution.dart ]]; then DART_FILE=solution.dart; else DART_FILE=snippet.dart; fi
        set -x
        dart format --output none --set-exit-if-changed $DART_FILE
      )
    done

}

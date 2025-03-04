#!/bin/bash

build_rpm() {
  rm -rf ./rpmbuild

  echo_color "\nCopying sources / patches:"
  mkdir -p ./rpmbuild/SOURCES

  if [ -d "$source_dir" ]; then
    cp -r ./sources ./rpmbuild/SOURCES/ &>/dev/null || true
  fi
  if [ -d "$patch_dir" ]; then
    cp -r ./patches ./rpmbuild/SOURCES/ &>/dev/null || true
  fi

  if [ "$(ls ./rpmbuild/SOURCES)" ]; then
    find ./rpmbuild/SOURCES -maxdepth 2 -type f
  else
    echo "No source / patch files"
  fi

  echo_color "\nRPM Lint"
  rpmlint ./$spec_file

  echo_color "\nRPM Build"
  echo_debug rpmbuild --define "_topdir $PWD/rpmbuild" -ba --noclean ./$spec_file

  echo_color "\n=== RPM Contents ==="

  # One-by-one for some separation
  for file in ./rpmbuild/RPMS/**/*.rpm; do
    echo_color "\nRPM <$file>:"

    echo_color "\nFiles:"
    rpm -qvlp $file

    echo_color "\nScripts:"
    rpm -qp --scripts $file
  done

  RPM_LOCAL_BUILD="true"
}

#!/bin/bash

build_rpm() {
  rm -rf ./rpmbuild

  echo_color "\nCopying sources / patches:"
  mkdir -p ./rpmbuild/SOURCES

  # SOURCE RPM builds do not accept anything in sub directories...
  # So do not use these and just get sources/patches in %prep
  # so repo organisation will be much better
  cp $spec_file ./rpmbuild/SOURCES/ &>/dev/null || true

  if [ "$(ls ./rpmbuild/SOURCES)" ]; then
    find ./rpmbuild/SOURCES -maxdepth 2 -type f
  else
    echo "No source / patch files"
  fi

  echo_color "\nRPM Lint"
  rpmlint ./$spec_file

  echo_color "\nRPM Build"
  run_debug rpmbuild --define "_topdir $PWD/rpmbuild" -ba --noclean ./$spec_file

  echo_color "\n=== RPM Contents ==="
  # One-by-one for some separation

  for file in ./rpmbuild/SRPMS/*.rpm; do
    echo_color "\nSource RPM <$file>:"

    echo_color "\nFiles:"
    rpm -qvlp $file

    echo_color "\nScripts:"
    rpm -qp --scripts $file
  done

  echo ""

  for file in ./rpmbuild/RPMS/**/*.rpm; do
    echo_color "\nRPM <$file>:"

    echo_color "\nFiles:"
    rpm -qvlp $file

    echo_color "\nScripts:"
    rpm -qp --scripts $file
  done

  RPM_LOCAL_BUILD="true"
}

#!/bin/bash

print_rpm_files() {
  echo_color "\nRPM file contents:"

  # One-by-one for some separation
  for file in ./rpmbuild/SRPMS/*.rpm; do
    echo_color -e -n "\nSource RPM: "
    echo " $file"

    echo_color "files:"
    rpm -qvlp $file

    echo_color "scripts:"
    rpm -qp --scripts $file
  done

  echo ""

  for file in ./rpmbuild/RPMS/**/*.rpm; do
    echo_color -e -n "\nRPM: "
    echo " $file"

    echo_color "files:"
    rpm -qvlp $file

    echo_color "scripts:"
    rpm -qp --scripts $file
  done
}

build_rpm() {
  rm -rf ./rpmbuild

  echo_color "Copying sources / patches:"
  mkdir -p ./rpmbuild/SOURCES

  # SOURCE RPM builds do not accept anything in sub directories...
  # So do not use these and just get sources/patches in %prep
  # so repo organisation will be much better
  cp $spec_file ./rpmbuild/SOURCES/ &>/dev/null || true
  cp -r ./sources ./rpmbuild/SOURCES/ &>/dev/null || true
  cp -r ./patches ./rpmbuild/SOURCES/ &>/dev/null || true

  if [ "$(ls ./rpmbuild/SOURCES)" ]; then
    find ./rpmbuild/SOURCES -maxdepth 2 -type f
  else
    echo "No source / patch files"
  fi

  echo_color "\nRPM Lint"
  rpmlint ./$spec_file

  echo_color "\nRPM Build"

  if [ "$without_local" = "true" ]; then
    # For debugging COPR in local builds
    run_debug rpmbuild --define "_topdir $PWD/rpmbuild" -ba --noclean ./$spec_file
  else
    run_debug rpmbuild --define "_topdir $PWD/rpmbuild" -ba --noclean --with local ./$spec_file
  fi

  RPM_LOCAL_BUILD="true"

  print_rpm_files
}

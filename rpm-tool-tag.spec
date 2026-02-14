# Create an option to build locally without fetchting own repo
# for sourcing and patching
%bcond local 0

# Source repo 1
%global author pvermeer
%global source rpm-tools
%global sourcerepo https://github.com/pvermeer/rpm-tools
%global tag v0.0.2

Name: rpm-tool
Version: 0.0.2
Release: 0%{?dist}
License: GPL-3.0 license
Summary: RPM build to test the rpm-tools.
Url: %{sourcerepo}

BuildRequires: git

%description
RPM build to test the rpm-tools

%define workdir %{_builddir}/%{name}
%define sourcedir %{workdir}/%{source}

%prep
# To apply working changes handle sources / patches locally
# COPR should clone the commited changes
%if %{with local}
  # Get sources - local build
  mkdir -p %{sourcedir}
  cp -r %{_topdir}/SOURCES/* %{sourcedir}
%else
  # Get sources - COPR build
  git clone %{sourcerepo} %{sourcedir}
  cd %{sourcedir}
  git reset --hard %{tag}
  cd %{workdir}
%endif

# Do src stuff
cd %{sourcedir}
rm -rf .git
cd %{workdir}

%build

%check

%install
mkdir -p %{buildroot}/etc/modprobe.d
mkdir -p %{buildroot}/lib/firmware

install %{sourcedir}/sources/source1.source %{buildroot}/lib/firmware
install %{sourcedir}/sources/source2.source %{buildroot}/etc/modprobe.d

%post
echo "POST SCRIPT HERE"

%files
/lib/firmware/source1.source
/etc/modprobe.d/source2.source

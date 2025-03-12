# Create an option to build locally without fetchting own repo
# for sourcing and patching
%bcond local 0

# Source repo 1
%global author pvermeer
%global source copr_realtek-alc887-vd
%global sourcerepo https://github.com/pvermeer/copr_realtek-alc887-vd
%global commit dbd6a2dc2f54b9bf89c86e34d750fbb75879865c
%global versioncommit %(echo -n %{commit} | head -c 8)

# Source repo 2
%global author2 pvermeer
%global source2 rpm-tools_copr_test_source
%global sourcerepo2 https://github.com/pvermeer/rpm-tools
%global branch2 copr_test_source
%global commit2 1ae517dbc21cde7965d60e285054de28aa2194b1
%global versioncommit2 %(echo -n %{commit2} | head -c 8)

# Own copr repo
%global coprrepo https://github.com/pvermeer/rpm-tools
%global coprsource rpm-tools

Name: rpm-tool
Version: 0.0.0
Release: %{versioncommit}.%{versioncommit2}%{?dist}
License: GPL-3.0 license
Summary: RPM build to test the rpm-tools.
Url: %{coprrepo}

BuildRequires: git

%description
RPM build to test the rpm-tools

%define workdir %{_builddir}/%{name}
%define coprdir %{workdir}/%{coprsource}
%define sourcedir %{workdir}/%{source}
%define sourcedir2 %{workdir}/%{source2}

%prep
# To apply working changes handle sources / patches locally
# COPR should clone the commited changes
%if %{with local}
  # Get sources / patches - local build
  mkdir -p %{coprdir}
  cp -r %{_topdir}/SOURCES/* %{coprdir}
%else
  # Get sources / patches - COPR build
  git clone %{coprrepo} %{coprdir}
  cd %{coprdir}
  rm -rf .git
  cd %{workdir}
%endif

# Get source1 repo
git clone %{sourcerepo} %{sourcedir}
cd %{sourcedir}
git reset --hard %{commit}

# Do src stuff

rm -rf .git
cd %{workdir}

# Get source2 repo
git clone %{sourcerepo2} %{sourcedir2}
cd %{sourcedir2}
git reset --hard %{commit2}

# Do src stuff
git apply %{coprdir}/patches/rpm-tools/src-to-be-patched.patch

# Quick test
grep "This is patched!" src/src-to-be-patched.sh || (echo "Patching failed" >&2 && false);

rm -rf .git
cd %{workdir}

%build

%install
mkdir -p %{buildroot}/etc/modprobe.d
mkdir -p %{buildroot}/lib/firmware

install %{coprdir}/sources/source1.source %{buildroot}/lib/firmware
install %{coprdir}/sources/source2.source %{buildroot}/etc/modprobe.d

%check

%post
echo "POST SCRIPT HERE"

%files
/lib/firmware/source1.source
/etc/modprobe.d/source2.source

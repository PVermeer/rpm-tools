# Create an option to build locally without fetchting own repo
# for sourcing and patching
%{!?with_local:%global with_local 0}

# Source repo 1
%global author pvermeer
%global source test_source
%global sourcerepo https://github.com/pvermeer/rpm-tools
%global tag v0.0.2
%global version %(tag="%{tag}"; echo ${tag#v})

# Own copr repo
%global coprrepo https://github.com/pvermeer/rpm-tools
%global coprsource rpm-tools

Name: rpm-tool
Version: %{version}
Release: 0%{?dist}
License: GPL-3.0 license
Summary: RPM build to test the rpm-tools.
Url: %{sourcerepo}

BuildRequires: git

%description
RPM build to test the rpm-tools

%define sourcesdir %{_builddir}/source
%define coprdir %{sourcesdir}/%{coprsource}
%define sourcedir %{sourcesdir}/%{source}

%prep
# To apply working changes handle sources / patches with local changes.
# COPR should clone the commited changes.
%if 0%{?with_local}
  mkdir -p %{coprdir}
  cp -r %{_topdir}/SOURCES/. %{coprdir}
%else
  git clone %{coprrepo} --depth=1 --no-checkout %{coprdir}
  cd %{coprdir}
  git fetch --depth=1 origin
  git reset --hard origin
  cd %{_builddir}
%endif

git clone %{sourcerepo} --depth=1 --no-checkout %{sourcedir}

cd %{sourcedir}
git fetch --depth=1 origin tag %{tag}
git reset --hard %{tag}
git submodule update --init --depth 1 --recursive
cd %{_builddir}

# Do src stuff

%build

%check

%install
mkdir -p %{buildroot}/etc/modprobe.d
mkdir -p %{buildroot}/lib/firmware

install %{coprdir}/sources/source1.source %{buildroot}/lib/firmware
install %{coprdir}/sources/source2.source %{buildroot}/etc/modprobe.d

%post
echo "POST SCRIPT HERE"

%files
/lib/firmware/source1.source
/etc/modprobe.d/source2.source

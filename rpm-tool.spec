# Create an option to build locally without fetchting own repo
# for sourcing and patching
%{!?with_local:%global with_local 0}

# Source repo 1
%global author pvermeer
%global source test_source
%global sourcerepo https://github.com/pvermeer/rpm-tools
%global branch copr_test_source
%global commit 9bd86bfa1391c47e878d05049b2db927aeaf10d3
%global versioncommit %(echo -n %{commit} | head -c 8)

# Source repo 2
%global author2 pvermeer
%global source2 test_source2
%global sourcerepo2 https://github.com/pvermeer/rpm-tools
%global branch2 copr_test_source2
%global commit2 4c729811648c20423062af4160a2490557a16519
%global versioncommit2 %(echo -n %{commit2} | head -c 8)

# Own copr repo
%global coprrepo https://github.com/pvermeer/rpm-tools
%global coprsource rpm-tools

Name: rpm-tool
Version: 0.0.2
Release: 4.%{versioncommit}.%{versioncommit2}%{?dist}
License: GPL-3.0 license
Summary: RPM build to test the rpm-tools.
Url: %{coprrepo}

BuildRequires: git

%description
RPM build to test the rpm-tools

%define sourcesdir %{_builddir}/source
%define coprdir %{sourcesdir}/%{coprsource}
%define sourcedir %{sourcesdir}/%{source}
%define sourcedir2 %{sourcesdir}/%{source2}

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
git clone %{sourcerepo2} --depth=1 --no-checkout %{sourcedir2}

cd %{sourcedir}
git fetch --depth=1 origin %{commit}
git reset --hard %{commit}
git submodule update --init --depth 1 --recursive
cd %{_builddir}

cd %{sourcedir2}
git fetch --depth=1 origin %{commit2}
git reset --hard %{commit2}
git submodule update --init --depth 1 --recursive
cd %{_builddir}

# Do src stuff
cd %{sourcedir2}
git apply %{coprdir}/patches/%{source2}/src-to-be-patched.patch
grep "This is also patched!" src/src-to-be-patched.sh || (echo "Patching failed" >&2 && false);
cd %{_builddir}

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

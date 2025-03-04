%global author pvermeer
%global repository https://github.com/pvermeer/copr_realtek-alc887-vd
%global commit 7615a58dfa1c7239f02aafa163573ff884576e3b
%global repository2 https://github.com/pvermeer/rpm-tools
%global branch2 test_branch_update
%global commit2 1beba126b60d29253d053cc2bfd5bdc3df6b69ae

%define versioncommit %(echo -n %{commit} | head -c 8)

Name: rpm-tool
Version: 0.0.0
Release: 1%{?dist}
License: GPL-3.0 license
Summary: RPM build to test the rpm-tools.
Url: https://github.com/%{author}/%{repository}

BuildRequires: git

%define workdir %{_builddir}/%{name}
%define sourcedir %{_topdir}/SOURCES

%description
RPM build to test the rpm-tools

%prep
mkdir -p %{workdir}
cp -r %{sourcedir}/* %{workdir}

%build

%install
mkdir -p %{buildroot}/etc/modprobe.d
mkdir -p %{buildroot}/lib/firmware

install %{workdir}/sources/source1.source %{buildroot}/lib/firmware
install %{workdir}/sources/source2.source %{buildroot}/etc/modprobe.d

%check

%files
/lib/firmware/source1.source
/etc/modprobe.d/source2.source

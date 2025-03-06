# Example SPEC file (that should work)

%global author pvermeer
%global repository https://github.com/pvermeer/copr_realtek-alc887-vd
%global commit 7615a58dfa1c7239f02aafa163573ff884576e3b
%global repository2 https://github.com/pvermeer/rpm-tools
%global branch2 test_branch_update
%global commit2 d9364a32c0e8313ed5f9be152fa770fd37f889a6

# Own repo to get patches / sources
%define ownrepo https://github.com/pvermeer/rpm-tools
%define coprrepo git_copr_rpm-tools

%define repo git_copr_realtek-alc887-vd
%define repo2 git_rpm-tools

%define versioncommit %(echo -n %{commit} | head -c 8)
%define versioncommit2 %(echo -n %{commit2} | head -c 8)

Name: rpm-tool
Version: 0.0.0
Release: %{versioncommit}.%{versioncommit2}%{?dist}
License: GPL-3.0 license
Summary: RPM build to test the rpm-tools.
Url: https://github.com/%{author}/%{repository}

BuildRequires: git

%define workdir %{_builddir}/%{name}
%define coprdir %{workdir}/%{coprrepo}
%define sourcedir %{workdir}/%{repo}
%define sourcedir2 %{workdir}/%{repo2}

%description
RPM build to test the rpm-tools

%prep
# Get all sources externally.
# RPM build does not allow subdirs for sources/patches
# so do it ourself to keep things organised

# Copr files repo repo for sources and patches
git clone %{ownrepo} %{coprdir}
cd %{coprdir}

# Do src stuff

rm -rf .git
cd %{workdir}

# === Dependency repo
git clone %{repository} %{sourcedir}
cd %{sourcedir}
git reset --hard %{commit}

# Do src stuff

rm -rf .git
cd %{workdir}

# === Dependency repo 2
git clone %{repository2} %{sourcedir2}
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

#
# spec file for package yast2-schema
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           autoyast2-schemas
Version:        0.0.1
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:	        System/YaST
License:        GPL-2.0+

Url:            https://github.com/yast/autoyast2-schemas

# XXX: SLE-12 build packages for x86 and s390, but no runnable kernel, so
# this package cannot be build here. Remove when SLE stop doing it
%if !0%{?is_opensuse}
ExcludeArch:    %ix86 s390
%endif

# Dependencies needed to build the package
BuildRequires:	trang yast2-devtools
# yast2-devtools yast2-testsuite

# All packages providing RNG files for AutoYaST
# in /usr/share/YaST2/schema/autoyast/rng/*.rng
Summary:	YaST2 - All AutoYaST Schemas

%description
All AutoYaST Syntax Schemas

%prep
%setup -n %{name}-%{version}
# %setup

%build
for target in src/*
do
    TARGET=$(basename $target) ./scripts/collect.sh
done

%install
install -m755 -d %{buildroot}%{yast_schemadir}/autoyast
cp -r build/* %{buildroot}%{yast_schemadir}/autoyast/

%files
%defattr(-,root,root)
%dir %{yast_schemadir}
%dir %{yast_schemadir}/autoyast
%dir %{yast_schemadir}/autoyast/sle-*
%dir %{yast_schemadir}/autoyast/sle-*/rnc
%{yast_schemadir}/autoyast/sle-*/rnc/*.rnc
%dir %{yast_schemadir}/autoyast/sle-*/rng
%{yast_schemadir}/autoyast/sle-*/rng/*.rng
%license COPYING

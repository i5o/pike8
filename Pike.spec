Name: pike
Version: 8.0
Summary: pike 8.0 is 8th version of pike programming language
Release: 8
Copyright: GPL
Packager: Tymon Radzik <dwgipk@gmail.com>
URL: http://pike.lysator.liu.se/
Source: http://tymonradzik.pl/pike-8.0.tar.gz

%description
Pike is a dynamic programming language with a syntax similar to Java and C. It is simple to learn, does not require long compilation passes and has powerful built-in data types allowing simple and really fast data manipulation.

%build
make

%install
make install

%files
%doc CHANGES COPYING COPYRIGHT README README-GIT ANNOUNCE

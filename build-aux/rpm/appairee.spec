%global app_id fr.benjaminbellamy.Appairee

Name:           appairee
Version:        1.1.0
Release:        1%{?dist}
Summary:        Settings for the Sennheiser BTD 700 Bluetooth dongle

License:        GPL-3.0-or-later
URL:            https://github.com/benjaminbellamy/appairee
Source0:        %{url}/archive/%{version}/%{name}-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  meson >= 1.0.0
BuildRequires:  vala
BuildRequires:  blueprint-compiler
BuildRequires:  gettext
BuildRequires:  desktop-file-utils
BuildRequires:  appstream
# Defines %%{_udevrulesdir}, which is not a core rpm macro.
BuildRequires:  systemd-rpm-macros
BuildRequires:  pkgconfig(gtk4) >= 4.10
BuildRequires:  pkgconfig(libadwaita-1) >= 1.5
BuildRequires:  pkgconfig(glib-2.0) >= 2.74
BuildRequires:  pkgconfig(hidapi-hidraw)
BuildRequires:  pkgconfig(alsa)

%description
The Sennheiser BTD 700 needs no driver on Linux: it appears as an ordinary
USB sound card. What no Linux software can reach are the settings stored
inside the dongle itself, which Sennheiser exposes only through its Windows
and macOS application.

Appairee reaches them. Switch the dongle to gaming mode for low latency,
pick the Bluetooth codec, and read back what the dongle is actually doing.
It also collects the status LED colour legend and every gesture of the
dongle's single button, which the printed manual scatters across a dozen
pages.

The dongle protocol is btd700ctl by sobalap, built in.

%prep
%autosetup

%build
# The udev rule is what makes the dongle reachable by a normal user; a
# package can install it, which is the whole reason for shipping one.
%meson -Dudev_rules_dir=%{_udevrulesdir}
%meson_build

%install
%meson_install
%find_lang %{name}

%check
%meson_test

%files -f %{name}.lang
%license LICENSE
%doc README.md
%{_bindir}/%{name}
%{_datadir}/applications/%{app_id}.desktop
%{_datadir}/glib-2.0/schemas/%{app_id}.gschema.xml
%{_datadir}/icons/hicolor/scalable/apps/%{app_id}.svg
%{_datadir}/icons/hicolor/symbolic/apps/%{app_id}-symbolic.svg
%{_datadir}/metainfo/%{app_id}.metainfo.xml
%{_datadir}/%{name}/99-btd700.rules
%{_udevrulesdir}/60-appairee-btd700.rules

%changelog
* Sun Sep 06 2026 Benjamin Bellamy <benjamin@castopod.org> - 1.1.0-1
- Add a volume slider for the dongle's own output level.

* Sat Sep 05 2026 Benjamin Bellamy <benjamin@castopod.org> - 1.0.0-1
- First release.

project(
  'appairee',
  ['c', 'vala'],
  version: '1.1.0',
  license: 'GPL-3.0-or-later',
  meson_version: '>= 1.0.0',
  default_options: [
    'warning_level=2',
    'c_std=gnu11',
  ],
)

i18n = import('i18n')
gnome = import('gnome')

app_id = 'fr.benjaminbellamy.Appairee'
gettext_package = meson.project_name()

prefix = get_option('prefix')
datadir = prefix / get_option('datadir')
localedir = prefix / get_option('localedir')

conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('APP_NAME', 'Appairée')
conf.set_quoted('GETTEXT_PACKAGE', gettext_package)
conf.set_quoted('LOCALEDIR', localedir)
conf.set_quoted('PKGDATADIR', datadir / 'appairee')
conf.set_quoted('VERSION', meson.project_version())

configure_file(output: 'config.h', configuration: conf)
config_inc = include_directories('.')

# Vala emits #include <glib/gi18n-lib.h>, which refuses to compile unless
# GETTEXT_PACKAGE is already defined by the preprocessor.
add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_package), language: 'c')

subdir('data')
subdir('src')
subdir('po')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)

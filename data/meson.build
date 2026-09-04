desktop_file = i18n.merge_file(
  input: '@0@.desktop.in'.format(app_id),
  output: '@0@.desktop'.format(app_id),
  type: 'desktop',
  po_dir: '../po',
  install: true,
  install_dir: datadir / 'applications',
)

desktop_file_validate = find_program('desktop-file-validate', required: false)
if desktop_file_validate.found()
  test('validate-desktop-file', desktop_file_validate, args: [desktop_file])
endif

metainfo_file = i18n.merge_file(
  input: '@0@.metainfo.xml.in'.format(app_id),
  output: '@0@.metainfo.xml'.format(app_id),
  po_dir: '../po',
  install: true,
  install_dir: datadir / 'metainfo',
)

appstreamcli = find_program('appstreamcli', required: false)
if appstreamcli.found()
  test(
    'validate-metainfo-file',
    appstreamcli,
    args: ['validate', '--no-net', '--explain', metainfo_file],
  )
endif

install_data(
  '@0@.gschema.xml'.format(app_id),
  install_dir: datadir / 'glib-2.0' / 'schemas',
)

glib_compile_schemas = find_program('glib-compile-schemas', required: false)
if glib_compile_schemas.found()
  test(
    'validate-gsettings-schema',
    glib_compile_schemas,
    args: ['--strict', '--dry-run', meson.current_source_dir()],
  )
endif

install_subdir('icons/hicolor', install_dir: datadir / 'icons')

# Always shipped, so the application can point at a real file and offer the exact
# command to install it.
install_data(
  '99-btd700.rules',
  install_dir: datadir / 'appairee',
)

# A native package installs it into udev's own directory, where it takes effect
# without the user doing anything. A Flatpak cannot: it has no way to write to
# the host, which is why the in-app instructions exist at all.
udev_rules_dir = get_option('udev_rules_dir')
if udev_rules_dir != ''
  install_data(
    '99-btd700.rules',
    install_dir: udev_rules_dir,
    rename: '60-appairee-btd700.rules',
  )
endif

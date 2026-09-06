appairee_sources = files(
  'config.vapi',
  'btd700.vapi',
  'appairee-intl.vapi',
  'appairee-volume.vapi',
  'main.vala',
  'application.vala',
  'device.vala',
  'language.vala',
  'led.vala',
  'ui/window.vala',
  'ui/about-dialog.vala',
  'ui/dongle-dialog.vala',
  'ui/manual-dialog.vala',
)

cc = meson.get_compiler('c')

# hidapi is found by name for the link. Meson hands a pkg-config dependency to
# valac as --pkg, and hidapi has no VAPI, so dependency('hidapi-hidraw') among
# the executable's dependencies makes valac fail before it compiles anything.
# The vendored C below gets the real pkg-config dependency, which valac never
# sees; the Vala side talks to btd700ctl through btd700.vapi and never mentions
# hidapi at all.
hidapi_dep = cc.find_library('hidapi-hidraw')

# libasound is found by name for the link, for the same reason as hidapi above.
# Vala does ship an alsa.vapi, so dependency('alsa') here would not break the
# build the way hidapi did, but it would put a second, incomplete binding in
# front of valac. The Vala side talks to ALSA only through appairee-volume.vapi.
asound_dep = cc.find_library('asound')

# fmod() in the LED animation.
m_dep = cc.find_library('m', required: false)

# btd700ctl, vendored unmodified under src/btd700ctl (see the README there).
# Compiled here rather than depended on, so that building Appairée needs nothing
# installed but hidapi. It gets its own target with warnings off: it is
# upstream's code, not ours to tidy, and it should not be held to this project's
# warning level.
btd700ctl_lib = static_library(
  'btd700ctl',
  'btd700ctl/btd700.c',
  dependencies: [dependency('hidapi-hidraw')],
  include_directories: include_directories('btd700ctl', 'btd700ctl/include'),
  c_args: ['-w'],
)

appairee_deps = [
  dependency('glib-2.0', version: '>= 2.74'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
  dependency('gtk4', version: '>= 4.10'),
  dependency('libadwaita-1', version: '>= 1.5'),
  hidapi_dep,
  asound_dep,
  m_dep,
]

# Hand-written C keeps the project's full warning level. Only the C that valac
# generates gets the exemptions below, which is why the shim is its own target.
appairee_shim = static_library(
  'appairee-shim',
  'appairee-intl.c',
  'appairee-volume.c',
  dependencies: [
    dependency('glib-2.0'),
    dependency('alsa'),
  ],
  include_directories: config_inc,
)

blueprints = custom_target(
  'blueprints',
  input: files(
    'ui/window.blp',
    'ui/about-dialog.blp',
    'ui/dongle-dialog.blp',
    'ui/manual-dialog.blp',
  ),
  output: '.',
  command: [
    find_program('blueprint-compiler'),
    'batch-compile',
    '@OUTPUT@',
    '@CURRENT_SOURCE_DIR@',
    '@INPUT@',
  ],
)

appairee_resources = gnome.compile_resources(
  'appairee-resources',
  'appairee.gresource.xml',
  dependencies: blueprints,
)

vala_generated_c_args = [
  # The C that valac generates trips these by design; they say nothing about our
  # code, and each one measurably suppresses warnings that no source change can.
  # Hand-written C gets its own target so it keeps the full warning set.
  '-Wno-unused-parameter',
  '-Wno-unused-but-set-variable',
  '-Wno-unused-variable',
  '-Wno-discarded-qualifiers',
  # valac allocates zero-length arrays with g_new0(T, 0), which is legal and
  # which -Wextra flags anyway.
  '-Wno-alloc-size',
]

executable(
  'appairee',
  appairee_sources,
  appairee_resources,
  dependencies: appairee_deps,
  link_with: [appairee_shim, btd700ctl_lib],
  include_directories: [
    config_inc,
    include_directories('.'),
    include_directories('btd700ctl/include'),
  ],
  c_args: vala_generated_c_args,
  vala_args: ['--vapidir', meson.current_source_dir()],
  install: true,
)

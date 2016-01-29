## SIMP Packer manifests


`~/bin/packer validate simp.json`

**NOTE**
`~/bin/packer build --debug simp.json`

### TODO
- [ ] fix sudo tty issue
- [ ] work on `<wait10>` timings
- [ ] **???** put paths, credentials in `-var-` or `-var-file`?

#### sudo tty issue
```
==> virtualbox-iso: Connected to SSH!
==> virtualbox-iso: Uploading VirtualBox version info (5.0.10)
==> virtualbox-iso: Uploading VirtualBox guest additions ISO...
==> virtualbox-iso: Gracefully halting virtual machine...
    virtualbox-iso: sudo: sorry, you must have a tty to run sudo
```

### `packer build --help`
```
Usage: packer build [options] TEMPLATE

  Will execute multiple builds in parallel as defined in the template.
  The various artifacts created by the template will be outputted.

Options:

  -debug                     Debug mode enabled for builds
  -force                     Force a build to continue if artifacts exist, deletes existing artifacts
  -machine-readable          Machine-readable output
  -except=foo,bar,baz        Build all builds other than these
  -only=foo,bar,baz          Only build the given builds by name
  -parallel=false            Disable parallelization (on by default)
  -var 'key=value'           Variable for templates, can be used multiple times.
  -var-file=path             JSON file containing user variables.
```

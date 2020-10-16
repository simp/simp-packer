# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Support for SIMP 6.5.0 Alpha

### Changed
- Use 'simp::classes' in lieu of 'classes' in hieradata.
- Use 'rndc-key' in lieu of 'rndckey' in named.conf to match the generated
  key name. (In SIMP 6.5.0 we no longer deliver the sample rndc.key file,
  whose key name is 'rndckey'.)
- Examples explicitly target SIMP 6.5.0 (instead of "6.X")
- 'site' module dependency version ranges now accomodate SIMP 6.5.0
- Converted CHANGELOG into format documented at https://keepachangelog.com/
- Refined regex used to check for puppetserver and puppetdb service status to
  support both Puppet 5 and Puppet 6.
- Update JSON comments to work with Packer 1.5+

### Removed
- Dropped support for all SIMP releases older than 6.5.0
  - Removed data -> hieradata cruft (for SIMP < 6.3.0
  - The named.conf rndc-key -> rndckey change is incompatible with
    SIMP 6.4.0 and earlier
  - Use an earlier version of simp-packer if you need to build SIMP
    <= 6.4.0.

### Fixed
- Enabled FIPS mode in the `fips7` sample's `simp_conf.yaml`
- Local site module is now appended to the environment's
  Puppetfile so that the module persists when r10k is used to
  deploy the modules in upgrade tests.
- Removed extraneous call to puppet-usersetup.sh from simp-bootstrap.sh.
  This script was called already called between `simp config` and
  `simp bootstrap`.

## [2.4.0] - 2019-07-05

The release adds SIMP 6.4.0 support and several new rake tasks

### Added
- New rake task: `simp:packer:build`
- New Rake task: `packer:validate`
- Initial Ruby Unit tests
- Each matrix log now includes information about its iteration
- Support for SIMP 6.4.0 RC1, which has new changes to simp-cli.
- Support for simp-cli 6.4 alpha (version 5.0.0).  This puts things in
  the production environment.  Added packer user variable `simpenvironment`,
  so the directory where files are copied to can be changed.
- However: the scripts that run on the server use `puppet config` to
  determine environment and we do not yet use the packer user variable
  `simpenvironment` to set the environment in the `puppet.conf` file.
  It is only used to copy files to the correct directory.
- Must use:
  - simp-environment-skeleton >= 7.0.0
  - simp-rsync-skeleton >= 7.0.0
  - simp-adapter >= 1.0.0
  - simp-cli >= 5.0.0
  - simp-utils >= 6.2.0
- Updated to work with new r10k iso install process.
- Added site module installation with vagrant user manifest because site
  module is not installed.
- New rake task `simp:packer:oldbuild` to run with just test directory
  like the old days for a temporary bridge.

### Changed
- Refactored `simp_config.rb` and `simp_packer_test.sh` into code under `lib/`
- simp.json file to use simpenv script in simp-utils
- Changed `simp.json` template to reflect new flow.  (Note: Used a temp script
  to model simp env changes, see FIX ME.)
- Updated `simp_conf.yaml` in examples to reflect new simp cli changes.
- NOTE: Changes to `simp.json` template require packer version 1.4.0.  (The
  valid_exit_codes entry added during script reboot will ignore spurious errors
  that happen when the reboot script throws an error because it rebooted during
  the script.)

### Removed
- Support for puppet 4.10 and ruby 2.1.9.
- It will no longer work with older builds.  You need to checkout version
  2.3.0 to build an older version of SIMP.
- Linked file in site module (Packer can't handle linked files)
- Scripts: `simp_packer_test.sh` and `simp_config.rb`

### Fixed
- Fixed `VBoxManage hostonlyif ipconfig` logic
- Fixed errors in `simp:packer:build` logic


## [2.3.0] - 2018-11-15

This release supports Puppet 5 and Hiera 5.


### Added
- `Simp::Packer::Publish::LocalDirTree.publish`
- Matrix logs include iteration report
- Matrix `encryption=on` automatically adds 2 minutes to `big_sleep`


### Changed
- Use Puppet 5 Hiera data paths (unless the version of SIMP is less than
  6.3.0)
- Matrix builds stop on failures in `simp_packer_test.sh`
- Forced environment in `scripts/puppet-usersetup.sh` to permit `vagrant`
  sudo access on boxes that don't run `scripts/simp-bootstrap.sh`
- Add a longer `big_sleep` by default for centos 6 + 7
- Renamed `rake vagrant:boxname` to `rake vagrant:json`


## [2.2.2] - 2018-10-02

This release is primarily a documentation update.

### Added
- README sections:
  - "Supported SIMP releases"
  - "Running a build matrix"
  - "TODO > Box roles"
  - Detailed sub-steps for "TODO > Features > Vagrant box directory tree"
  - SIMP GitHub badges
- Environment variable: `SIMP_PACKER_verbose=yes`
- Travis CI stage: 'Puppet 5.5 (SIMP 6.3+)'

### Changed
- README/documentation cleanup:
  - Cleaned up project structure
  - Rewrote most of the "Usage" section
    - Merged `matrix.md` documentation
  - Minor clarifications throughout the document
- Fixed redundant sudo bug in `templates/simp.json.template`

### Removed
- Top-level `metadata.json` file
- `matrix.md` file


## [2.2.1] - 2018-10-01

### Changed
- Reverted bug in `useradd::securetty`
- Fixed bug in `Vagrantfile.erb.erb`
- Improved matrix `json=` handling
- Updated matrix docs


## [2.2.0] - 2018-09-28

### Added
- Initial build matrix support
- Rake tasks:
  - `rake simp:packer:matrix[]` (experimental)
    - Iterates through a matrix of conditions to run `simp_packer_test.sh`
  - `rake vagrant:publish:local[]`
    - Install vagrant box into a local directory tree
    - Generates versioned metadata
- YARD support

### Changed
- Improved vagrant box tree logic and code documentation
- Fixed broken SIMP 6.1.0 support
  - (SIMP-5350) Fixed el6/udev/eth1 VM cloning bug
  - (SIMP-4482) Added umask to 6.1.0 `simp bootstrap`
- Fixed box name bug in `Vagrantfile.erb.erb`


## [2.1.1] - 2018-09-17

### Changed
- Fixed error in tftpboot erb in simpsetup.

## [2.1.0] - 2018-08-30

### Added
- Tests:
  - Shell scripts are linted by shellcheck.
  - Ruby code is linted by rubocop.
  - rspec-puppet tests check the `simpsetup` Puppet module
- Rake tasks:
  - `bundle exec rake test`: Runs all tests (rubocop, shellcheck, rspec)
  - `bundle exec rake clean`: Removes packer-breaking symlinks and fixtures
  - `bundle exec rake vagrant:boxname[]`: (experimental) Generates a JSON file
     that Vagrantfiles and beaker nodesets can use to compare box versions

### Changed
- Fixed/rewrote the Travis CI pipeline
- Cleaned up scripts and manifests:
  - Code conforms to common lint checks
  - Restructured puppet code:
    - Puppet code is now under `puppet/modules/` and `puppet/profiles/`.
    - Added module metadata and development files to `simpsetup`.
    - Unused manifest files have been given the suffix `.UNUSED`.
  - Added `rakelib/` directory for rake tasks
  - Added `lib/` directory for ruby code (prep for spec tests)
  - Fixed minor bugs
- README:
  - Restructured and expanded documentation
  - Added a diagram of the basic workflow and directory structure.
  - Added a troubleshooting section.
  - Converted `samples/README` to markdown and linked from the top-level
    `README.md`.
  - Added TODO checklist for upcoming tasks.
  - Documented important environment variables.
  - Automated Markdown TOC with `mzlogin/vim-markdown-toc` (vim plugin).
- Cleaned up `simp.json.template`
  - Added RHEL support, new variables, minor fixes for bugs and logic
  - Moved to `templates/`
  - Expanded comments and converted them into `//`-format, so text editors can
    use JavaScript syntax highlighting rules to correctly render the whole file.

## [2.0.0] - 2018-07-11

### Added
- Updated the code to work with packer version 1.2.4
- Updated manifests/scripts to work with SIMP 6.2 changes
- Added firmware option to allow for addition of UEFI testing but
  have not implemented UEFI code yet.
- Updated simpsetup to use primary network interface instead of hardcoded interface.

### Removed
- Removed old code and moved simp-testing to the main directory

## [0.1.0] - 2018-03-14

### Added
- Added ability to set root's umask prior to running 'simp config'.
  This allows testing of the fix to the SIMP 6.1.0 problem in which
  SIMP failed to bootstrap on a system on which root's umask has
  already been restricted to 077.
- Added tests to verify that the  puppetserver and puppetdb services
  are running after SIMP is bootstrapped.
- Minor code refactor/documentation updates.
- Checked in more example configurations.

## [0.1.0] - 2017-06-27

### Added
- Created functioning tests and infrastructure to run them in simp-testing/.
  When the tests succeed a bootstrapped, SIMP vbox is created.

## [0.0.3] - 2016-07-07

### Changed
* Packer configures SIMP boxes more

## [0.0.2] - 2016-07-14

### Added
* Packer configures SIMP boxes

## [0.0.1] - 2016-01-29

### Added
* Packer builds SIMP boxes

[Unreleased]: https://github.com/simp/simp-packer/compare/2.4.0...HEAD
[2.4.0]: https://github.com/simp/simp-packer/compare/2.3.0...2.4.0
[2.3.0]: https://github.com/simp/simp-packer/compare/2.2.2...2.3.0
[2.2.2]: https://github.com/simp/simp-packer/compare/2.2.1...2.2.2
[2.2.1]: https://github.com/simp/simp-packer/compare/2.2.0...2.2.1
[2.2.0]: https://github.com/simp/simp-packer/compare/2.1.1...2.2.0
[2.1.1]: https://github.com/simp/simp-packer/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/simp/simp-packer/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/simp/simp-packer/compare/0.1.0...2.0.0
[0.1.0]: https://github.com/simp/simp-packer/compare/0.0.3...0.1.0
[0.0.3]: https://github.com/simp/simp-packer/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/simp/simp-packer/compare/0.0.1...0.0.2
[0.0.1]: https://github.com/simp/simp-packer/releases/tag/0.0.1


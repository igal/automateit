# == PackageManager
#
# The PackageManager provides a way to manage packages, e.g., install,
# uninstall and query if the Apache package is installed with APT.
#
# Examples:
#
#   package_manager.installed?("apache2") # => false
#   package_manager.install("apache2") # => true
#   package_manager.installed?("apache2") # => true
#   package_manager.uninstall("apache2") # => true
#   package_manager.not_installed("apache2") # => true
#
# Commands can accept arrays:
#
#   package_manager.install("apache2", "bash")
#   package_manager.installed? %w(apache2 bash)
#
# Commands can also accept a single, annotated string as a manifest -- useful
# for installing large numbers of packages at once:
#
#   package_manager.install <<HERE, :with => :apt
#     # One per line
#     apache
#     bash
#
#     # Or many on the same line
#     sysvconfig sysv-rc-conf
#   HERE
#
# Commands can also accept a hash of names to paths -- necessary for installing
# packages stored on the filesystem:
#
#   # Is the package called "TracTags" installed? If not, run the installer
#   # with the "/tmp/tractags_latest" path as an argument:
#   package.manager.install({"TracTags" => "/tmp/tractags_latest"}, :with => :egg)
class AutomateIt::PackageManager < AutomateIt::Plugin::Manager
  # Alias for #install
  def add(*packages) dispatch_to(:install, *packages) end

  # Alias for #uninstall
  def remove(*packages) dispatch_to(:uninstall, *packages) end

  # Are these +packages+ installed?
  #
  # Options:
  # * :details -- Returns an array containing the boolean result value and an
  #   array with a subset of installed +packages+. Boolean, defaults to false.
  def installed?(*packages) dispatch(*packages) end

  # Are these +packages+ not installed? 
  #
  # Options:
  # * :details -- Returns an array containing the boolean result value and an
  #   array with a subset of +packages+ not installed. Boolean, defaults to false.
  def not_installed?(*packages) dispatch(*packages) end

  # Install these +packages+. Returns +true+ if any packages are installed
  # successfully; or +false+ if all packages were already installed.
  def install(*packages) dispatch(*packages) end

  # Uninstall these +packages+. Returns +true+ if any packages are uninstalled
  # successfully; or +false+ if none of the packages are installed.
  def uninstall(*packages) dispatch(*packages) end
end

# == PackageManager::BaseDriver
#
# Base class for all PackageManager drivers.
class AutomateIt::PackageManager::BaseDriver < AutomateIt::Plugin::Driver
  protected

  # Are these +packages+ installed? Works like PackageManager#installed?
  # but calls a block that actually checks whether the packages are
  # installed and returns an array of packages installed.
  #
  # For example:
  #   _installed_helper?("package1", "package2", :details => true) do |packages, opts|
  #     # Dummy code which reports that these packages are installed:
  #     ["package1]
  #   end
  def _installed_helper?(*packages, &block) # :yields: filtered_packages, opts
    _raise_unless_available

    packages, opts = args_and_opts(*packages)
    packages = _list_normalizer(packages)
    packages = packages.keys if Hash === packages

    available = block.call(packages, opts)
    truth = (packages - available).empty?
    result = opts[:details] ? [truth, available] : truth
    log.debug(PNOTE+"installed?(#{packages.inspect}) => #{truth}: #{available.inspect}")
    return result
  end

  # Are these +packages+ not installed?
  def _not_installed_helper?(*packages)
    _raise_unless_available

    # Requires that your PackageManager#installed? method is implemented.
    packages, opts = args_and_opts(*packages)
    packages = _list_normalizer(packages)
    packages = packages.keys if Hash === packages

    opts_for_check = opts.dup
    opts_for_check[:details] = true
    available = [installed?(packages, opts_for_check)].flatten
    missing = packages - available
    truth = (packages - missing).empty?
    result = opts[:details] ? [truth, missing] : truth
    log.debug(PNOTE+"not_installed?(#{packages.inspect}) => #{truth}: #{missing.inspect}")
    return result
  end

  # Install these +packages+. Works like PackageManager#install but calls a
  # block that's responsible for actually installing the packages and
  # returning true if the installation succeeded. This block is only called
  # if packages need to be installed and receives a filtered list of
  # packages that are guaranteed not to be installed on the system already.
  #
  # For example:
  #   _install_helper("package1", "package2", :quiet => true) do |packages, opts|
  #     # Dummy code that installs packages here, e.g:
  #     system("apt-get", "install", "-y", packages)
  #   end
  def _install_helper(*packages, &block) # :yields: filtered_packages, opts
    _raise_unless_available

    packages, opts = args_and_opts(*packages)
    packages = _list_normalizer(packages)

    check_packages = \
      case packages
      when Hash
        packages.keys
      else 
        packages
      end

    opts_for_check = opts.dup
    opts_for_check[:details] = true

    missing = not_installed?(check_packages, opts_for_check)[1]
    return false if missing.blank?

    install_packages = \
      case packages
      when Hash
        missing.map{|t| packages[t]}
      else 
        missing
      end
    block.call(install_packages, opts)

    return true if preview?
    unless (failed = not_installed?(check_packages, opts_for_check)[1]).empty?
      raise ArgumentError.new("Couldn't install: #{failed.join(' ')}")
    else
      return true
    end
  end

  # Uninstall these +packages+. Works like PackageManager#uninstall but calls a
  # block that's responsible for actually uninstalling the packages and
  # returning true if the uninstall succeeded. This block is only called
  # if packages need to be uninstalled and receives a filtered list of
  # packages that are guaranteed to be installed on the system.
  #
  # For example:
  #   _uninstall_helper("package1", "package2", :quiet => true) do |packages, opts|
  #     # Dummy code that removes packages here, e.g:
  #     system("apt-get", "remove", "-y", packages)
  #   end
  def _uninstall_helper(*packages, &block) # :yields: filtered_packages, opts
    _raise_unless_available

    packages, opts = args_and_opts(*packages)
    packages = _list_normalizer(packages)

    check_packages = \
      case packages
      when Hash
        packages.keys
      else 
        packages
      end

    opts_for_check = opts.dup
    opts_for_check[:details] = true

    present = installed?(check_packages, opts_for_check)[1]
    return false if present.blank?

    uninstall_packages = \
      case packages
      when Hash
        present.map{|t| packages[t]}
      else 
        present
      end
    block.call(uninstall_packages, opts)

    return true if preview?
    unless (failed = installed?(check_packages, opts_for_check)[1]).empty?
      raise ArgumentError.new("Couldn't uninstall: #{failed.join(' ')}")
    else
      return true
    end
  end

  # Returns a normalized array of packages. Transforms manifest string into
  # packages. Turns symbols into string, strips blank lines and comments.
  def _list_normalizer(*packages)
    packages = [packages].flatten
    if packages.size == 1
      packages = packages.first
      nitpick "LN SI %s" % packages.inspect
      nitpick "LN Sc %s" % packages.class
      case packages
      when Symbol
        nitpick "LN Sy"
        packages = [packages.to_s]
      when String
        nitpick "LN Ss"
        packages = _string_to_packages(packages)
      when Hash
        # Don't do anything
        nitpick "LN Sh"
      else
        nitpick "LN S?"
        raise TypeError.new("Unknown input type: #{packages.class}")
      end
      nitpick "LN SO %s" % packages.inspect
    end

    case packages
    when Array
      result = packages.map(&:to_s).map{|t| _string_to_packages(t)}.flatten.uniq
    when Hash
      result = packages.stringify_keys
    when Symbol, String
      result = packages.to_s
    else
      raise TypeError.new("Unknown input type: #{packages.class}")
    end

    nitpick "LN RR %s" % result.inspect
    return result
  end

  def _string_to_packages(string)
    string.scan(/^\s*([^#]+)\s*/).flatten.map{|t| t.split}.flatten.uniq
  end
end

# Drivers
require 'automateit/package_manager/dpkg'
require 'automateit/package_manager/apt'
require 'automateit/package_manager/yum'
require 'automateit/package_manager/gem'
require 'automateit/package_manager/egg'
require 'automateit/package_manager/portage'
require 'automateit/package_manager/pear'
require 'automateit/package_manager/pecl'
require 'automateit/package_manager/cpan'

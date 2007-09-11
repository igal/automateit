# == PackageManager
#
# The PackageManager provides a way to manage packages, e.g., install,
# uninstall and query if the Apache package is installed with APT.
#
# Examples:
#   package_manager.installed?("apache2") # => false
#   package_manager.install("apache2") # => true
#   package_manager.installed?("apache2") # => true
#   package_manager.uninstall("apache2") # => true
#   package_manager.not_installed("apache2") # => true
class AutomateIt::PackageManager < AutomateIt::Plugin::Manager
  # Are these +packages+ installed? Returns +true+ if all +packages+ are
  # installed, or an array of installed packages when called with an options
  # hash that contains <tt>:list => true</tt>
  def installed?(*packages) dispatch(*packages) end

  # Are these +packages+ not installed? Returns +true+ if none of these
  # +packages+ are installed, or a array of packages that aren't installed
  # when called with an options hash that contains <tt>:list => true</tt>
  def not_installed?(*packages) dispatch(*packages) end

  # Install these +packages+. Returns +true+ if install succeeded; or
  # +false+ if all packages were already installed.
  def install(*packages) dispatch(*packages) end

  # Uninstall these +packages+. Returns +true+ if uninstall succeeded; or
  # +false+ if none of the packages were installed.
  def uninstall(*packages) dispatch(*packages) end
end

# == PackageManager::AbstractDriver
#
# Base class for all PackageManager drivers.
#
# It provides methods that make it easier to write PackageManager drivers. It
# can't install packages itself, but its helper methods make it easier for
# other drivers to do this by providing them with a bunch of common
# functionality that would otherwise have to be duplicated in each driver.
# These helpers are generic enough to be useful for all sorts of PackageManager
# driver implementations. Read the APT driver for good usage examples.
class AutomateIt::PackageManager::AbstractDriver < AutomateIt::Plugin::Driver
  protected

  # Are these +packages+ installed? Works like PackageManager#installed?
  # but calls a block that actually checks whether the packages are
  # installed and returns an array of packages installed.
  #
  # For example:
  #   _installed_helper?("package1", "package2", :list => true) do |packages, opts|
  #     # Dummy code which reports that these packages are installed:
  #     ["package1]
  #   end
  def _installed_helper?(*packages, &block) # :yields: filtered_packages, opts
    _raise_unless_available

    packages, opts = args_and_opts(*packages)
    packages = [packages].flatten
    packages = packages.map{|t|t.to_s}

    available = block.call(packages, opts)
    truth = (packages - available).empty?
    result = opts[:list] ? available : truth
    log.debug(PNOTE+"installed?(#{packages.inspect}) => #{truth}: #{available.inspect}")
    return result
  end

  # Are these +packages+ not installed?
  def _not_installed_helper?(*packages)
    _raise_unless_available

    # Requires that your PackageManager#installed? method is implemented.
    packages, opts = args_and_opts(*packages)
    packages = [packages].flatten
    packages = packages.map{|t|t.to_s}

    available = [installed?(packages, :list => true)].flatten
    missing = packages - available
    truth = (packages - missing).empty?
    result = opts[:list] ? missing : truth
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
    packages = [packages].flatten
    packages = packages.map{|t|t.to_s}

    missing = not_installed?(packages, :list => true)
    return false if missing.blank?
    block.call(missing, opts)
    return true if noop?
    unless (failed = not_installed?(missing, :list => true)).empty?
      raise ArgumentError.new("couldn't install: #{failed.join(' ')}")
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
    packages = [packages].flatten
    packages = packages.map{|t|t.to_s}

    present = installed?(packages, :list => true)
    return false if present.blank?
    block.call(present, opts)
    return true if noop?
    unless (failed = installed?(present, :list => true)).empty?
      raise ArgumentError.new("couldn't uninstall: #{failed.join(' ')}")
    else
      return true
    end
  end
end

# Drivers
require 'automateit/package_manager/apt'
require 'automateit/package_manager/yum'
require 'automateit/package_manager/gem'
require 'automateit/package_manager/egg'

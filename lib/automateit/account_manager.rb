module AutomateIt
  # == AccountManager
  #
  # The AccountManager provides a way of managing system accounts, such as UNIX
  # users and groups.
  class AccountManager < Plugin::Manager
    require 'automateit/account_manager/portable'
    require 'automateit/account_manager/linux'

    # Find a user account. Method returns a query helper which takes a
    # +username+ as an index argument and returns a Struct::Passwd entry as
    # described in Etc::getpwent if the user exists or a nil if not.
    #
    # Example:
    #   users["root"] # => #<struct Struct::Passwd name="root"...
    #
    #   users["does_not_exist"] # => nil
    def users() dispatch() end

    # Add the +username+ if not already created.
    #
    # Options:
    # * :description - User's full name. Defaults to username.
    # * :home - Path to user's home directory. If not specified, uses system
    #   default like "/home/username".
    # * :create_home - Create homedir. Defaults to true.
    # * :groups - Array of group names to add this user to.
    # * :shell - Path to login shell. If not specified, uses system default
    #   like "/bin/bash".
    # * :uid - Fixnum user ID for user. Default chooses an unused id.
    # * :gid - Fixnum group ID for user. Default chooses same gid as uid.
    #
    # Example:
    #   add_user("bob", :description => "Bob Smith")
    def add_user(username, opts={}) dispatch(username, opts) end

    def update_user(username, opts={}) dispatch(username, opts) end

    # Remove the +username+ if present.
    #
    # Options:
    # * :remove_home - Delete user's home directory and mail spool. Default is
    #   true.
    def remove_user(username, opts={}) dispatch(username, opts) end

    # Is +user+ present?
    def has_user?(user) dispatch(user) end

    # Add +groups+ (array of groupnames) to +user+.
    def add_groups_to_user(groups, user) dispatch(groups, user) end

    # Remove +groups+ (array of groupnames) from +user+.
    def remove_groups_from_user(groups, user) dispatch(groups, user) end

    #.......................................................................

    # Find a group. Method returns a query helper which takes a
    # +groupname+ as an index argument and returns a Struct::Group entry as
    # described in Etc::getgrent if the group exists or a nil if not.
    #
    # Example:
    #   groups["root"] # => #<struct Struct::Group name="root"...
    #
    #   groups["does_not_exist"] # => nil
    def groups() dispatch() end

    # Add +groupname+ if it doesn't exist. Options:
    # * :members - Array of usernames to add as members.
    # * :gid - Group ID to use. Default is to find an unused id.
    def add_group(groupname, opts={}) dispatch(groupname, opts) end

    def update_group(groupname, opts={}) dispatch(groupname, opts) end

    # Remove +groupname+ if it exists.
    def remove_group(groupname, opts={}) dispatch(groupname, opts) end

    # Does +group+ exist?
    def has_group?(group) dispatch(group) end

    # Add +users+ (array of usernames) to +group+.
    def add_users_to_group(users, group) dispatch(users, group) end

    # Remove +users+ (array of usernames) from +group+.
    def remove_users_from_group(users, group) dispatch(users, group) end

    # Array of groupnames this user is a member of.
    def groups_for_user(query) dispatch(query) end

    # Array of usernames in group.
    def users_for_group(query) dispatch(query) end

    # Hash of usernames and the groupnames they're members of.
    def users_to_groups() dispatch() end
  end # class AccountManager
end # module AutomateIt



require 'redmine'
require 'redmine_task_board_hook_listener'

Rails.configuration.to_prepare do
  require_dependency 'projects_helper'
  ProjectsHelper.send(:include, RedmineTaskBoardSettingsPatch) unless ProjectsHelper.included_modules.include?(RedmineTaskBoardSettingsPatch)
end

Redmine::Plugin.register :redmine_task_board do
  name 'Redmine Task Board 2'
  author 'Peter Pfläging'
  description 'Add a Kanban-style task board tab to projects'
  version '1.2.0'
  url 'https://github.com/netaustin/redmine_task_board'

  settings :partial => 'settings/redmine_task_board_settings',
           :default => {
           }

  project_module :taskboard do
    permission :edit_taskboard, {:projects => :settings, :taskboard => [:create_column, :delete_column, :update_columns, :create_defaultcolumns]}, :require => :member
    permission :view_taskboard, {:taskboard => [:index, :save]}, :require => :member
  end
  menu :project_menu, :taskboard, { :controller => 'taskboard', :action => 'index' }, :caption => :task_board_title, :before => :issues, :param => :project_id
end

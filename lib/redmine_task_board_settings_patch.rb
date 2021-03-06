require_dependency 'projects_helper'

module RedmineTaskBoardSettingsPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :project_settings_tabs, :taskboard_tab
    end
  end

  module InstanceMethods
    # Adds a task board tab to the user administration page
    def project_settings_tabs_with_taskboard_tab
      tabs = project_settings_tabs_without_taskboard_tab
      is_allowed = User.current.allowed_to?(:edit_taskboard, @project)
      # logger.info("++PP: taskboard_tab: #{is_allowed.inspect}")
      if is_allowed then
        tabs << { :name => 'taskboard', :partial => 'settings/project', :label => :label_task_board}
      end
      return tabs
    end
  end
end

module TaskboardHelper
  def authorCollect(project)
    return project.assignable_users.collect { |m| [m.name, m.id]}
  end
end

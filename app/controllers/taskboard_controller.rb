class TaskboardController < ApplicationController
  unloadable

  before_filter :find_project
  # before_filter :authorize
  helper_method :column_manager_locals
  helper TagsHelper if defined?(TagsHelper)
  helper :queries
  include QueriesHelper

  def index
    # logger.info("TaskboardController.index: '#{params.inspect}'")
    retrieve_query
    if @query.valid?
      @issues = @query.issues
      # logger.info "Query: #{@query.issues.inspect} "
    end
    @columns = TaskBoardColumn.where(:project_id => @project.id).order('weight').all()
    @status_names = Hash.new
    IssueStatus.select([:id, :name]).each do |status|
      @status_names[status.id] = status.name
    end
    @include_subprojects = \
          Setting.plugin_redmine_task_board['include_subprojects'].to_i == 1 &&
          @project.children.active.any?
    category_finder = :issue_categories
    if @include_subprojects && @project.respond_to?(:inherited_categories)
      category_finder = :inherited_categories
    end
    @categories = @project.send(category_finder)
  end




  def save
    failed_issues = []
    if params[:move] then
      params[:move].each do |issue_id, new_status_id|
        issue = Issue.find(issue_id)
        #        if issue.new_statuses_allowed_to(User.current).include?(IssueStatus.find(new_status_id))
        if User.current.allowed_to?(:edit_issues, @project)
          issue.init_journal(User.current)
          issue.update_attribute(:status_id, new_status_id)
          # count transaction if the module project_quota is installed and the method exists
          if defined? ProjectLimits::add_transaction
            ProjectLimits::add_transaction(@project)
          end
        else
          failed_issues << issue
        end
      end
    end
    if failed_issues.empty?
      params[:sort].each do |status_id, issues|
        weight = 0;
        issues.each do |issue_id|
          tbi = TaskBoardIssue.find_by_issue_id(issue_id).update_attribute(:project_weight, weight)
          weight += 1
        end
      end
    end
    respond_to do |format|
      format.js do
        if failed_issues.empty?
          head :ok
        else
#          response = failed_issues.map do |issue|
#            cards = TaskBoardIssue.find_all_by_issue_id(Project.all.first.issues.where(:status_id => issue.status_id)).sort{|a,b| a.project_weight <=> b.project_weight}
#            index = cards.index{|i| i.issue_id == issue.id}
#            prev_card_id = (index.nil? || index < 1) ? false : cards[index-1].issue_id
#            {:issue_id => issue.id, :status_id => issue.status_id, :previous_sibling_id => prev_card_id}
#          end
          render :json => response, :status => 403
        end
      end
    end
  end

# Create a default Column set (PP)
  def make_columns(project)
    #logger.info "++ PP: Setting Default TaskBoard"

    @project = project

    @state_ids = Hash.new
    IssueStatus.select([:id, :name]).each do |status|
      @state_ids[status.name] = status.id
      # logger.info "Status: #{status.name} -> #{status.id}"
    end

    TaskBoardColumn.where(:project_id => @project.id).all().each do |delproject|
      # logger.info "Delete: #{delproject.title}"
      delproject.delete
    end

    @column = TaskBoardColumn.new :project => @project, :title => l(:task_board_default_column_1)
    @column.save
    if state = @state_ids[l(:task_board_status_1)]
      StatusBucket.create!(:task_board_column_id => @column.id, :issue_status_id => state, :weight => 0)
    end

    @column = TaskBoardColumn.new :project => @project, :title => l(:task_board_default_column_2)
    @column.save
    if state = @state_ids[l(:task_board_status_2)]
      StatusBucket.create!(:task_board_column_id => @column.id, :issue_status_id => state, :weight => 0)
    end

    @column = TaskBoardColumn.new :project => @project, :title => l(:task_board_default_column_3)
    @column.save
    if state = @state_ids[l(:task_board_status_3)]
      StatusBucket.create!(:task_board_column_id => @column.id, :issue_status_id => state, :weight => 0)
    end

    @column = TaskBoardColumn.new :project => @project, :title => l(:task_board_default_column_4)
    @column.save
    if state = @state_ids[l(:task_board_status_4)]
      StatusBucket.create!(:task_board_column_id => @column.id, :issue_status_id => state, :weight => 0)
    end

    @column = TaskBoardColumn.new :project => @project, :title => l(:task_board_default_column_5)
    @column.save
    if state = @state_ids[l(:task_board_status_5)]
      StatusBucket.create!(:task_board_column_id => @column.id, :issue_status_id => state, :weight => 0)
    end

    @column = TaskBoardColumn.new :project => @project, :title => l(:task_board_default_column_6)
    @column.save
    if state = @state_ids[l(:task_board_status_6)]
      StatusBucket.create!(:task_board_column_id => @column.id, :issue_status_id => state, :weight => 0)
    end
    if state = @state_ids[l(:task_board_status_7)]
      StatusBucket.create!(:task_board_column_id => @column.id, :issue_status_id => state, :weight => 0)
    end
    if state = @state_ids[l(:task_board_status_8)]
      StatusBucket.create!(:task_board_column_id => @column.id, :issue_status_id => state, :weight => 0)
    end
  end

  def create_defaultcolumns
    make_columns(@project)
    render 'settings/update'
  end

  def create_column
    @column = TaskBoardColumn.new :project => @project, :title => params[:title]
    @column.save
    render 'settings/update'
  end

  def delete_column
    @column = TaskBoardColumn.find(params[:column_id])
    @column.delete
    render 'settings/update'
  end

  def update_columns
    if params[:column]
      params[:column].each do |column_id, new_state|
        column = TaskBoardColumn.find(column_id.to_i)
        # logger.info "Update: #{column.title} #{new_state[:weight]}. "
        column.weight = new_state[:weight].to_i
        column.max_issues = new_state[:max_issues].to_i
        # logger.info "++PP: update:_columns: #{column.title} #{column.inspect}. "
        column.save!
        column.status_buckets.clear()
      end
      if params[:status]
        params[:status].each do |column_id, statuses|
          statuses.each do |status_id, weight|
            status_id = status_id.to_i
            column_id = column_id.to_i
            # logger.info "---PP: StatusBucket column:#{column_id}, issue_status#{status_id}, weight:#{weight}"
            StatusBucket.create!(:task_board_column_id => column_id, :issue_status_id => status_id, :weight => weight)
          end
        end
      end
    end
    render 'settings/update'
  end

  private

  def find_project
    # @project variable must be set before calling the authorize filter
    if (params[:project_id]) then
      @project = Project.find(params[:project_id])
    elsif(params[:issue_id]) then
      @project = Issue.find(params[:issue_id]).project
    end
  end

end

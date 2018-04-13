module TaskboardHelper
  def authorCollect(project)
    return project.assignable_users.collect { |m| [m.name, m.id]}
  end

  def query_ids
    @queryids = []
    @query.issues.each do |i|
      @queryids.push(i.id)
    end
  end

  def selected_issue_per_column(column)
    # logger.info("+++PP: selected_issue_per_column")
    retval = []
    statusbuckets = []
    sb = {}
    query_ids
    # logger.info("--> Query IDs: #{@queryids}")
    StatusBucket.where(:task_board_column_id => column.id).each do |bucket|
      statusbuckets.push(bucket.issue_status_id)
      sb[bucket.issue_status_id] = []
    end
    # logger.info("---> Column: #{column.inspect} Statusbuckets: #{statusbuckets}")
    # logger.info("--->       : #{column.issues.inspect}")
    column.issues.each do |statusid, selissues|
      # logger.info("----> StatusID: #{statusid}, Issue: '#{selissues.inspect}'")
      selissues.each do |selissue|
        if selissue != nil
          sb[statusid].push(selissue) if @queryids.include? selissue.id
          # logger.info("-> #{[statusid, selissue].inspect}")
        end
      end
    end
    # logger.info("---> Struct of Issues: #{sb.inspect}")
    statusbuckets.each do |outbucket|
      retval.push([outbucket, sb[outbucket]])
    end
    # logger.info("--> Output: #{retval.inspect}")
    return retval
  end

  def _project_taskboard_path(project, *args)
    project ? project_taskboard_path(project, *args) : taskboard_path(*args)
  end
end
